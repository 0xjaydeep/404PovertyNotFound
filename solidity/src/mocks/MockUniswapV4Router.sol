// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interfaces/IUniswapV4Router.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MockUniswapV4Router
 * @dev Mock implementation of Uniswap V4 Router for testing InvestmentEngineV3
 * Simulates token swaps with configurable exchange rates and scenarios
 */
contract MockUniswapV4Router is IUniswapV4Router {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(address => uint256)) public exchangeRates; // tokenIn => tokenOut => rate (scaled by 1e18)
    mapping(address => mapping(address => bool)) public poolExists;
    mapping(address => bool) public shouldFailSwap; // For testing error scenarios

    uint256 public slippage = 50; // 0.5% slippage simulation
    bool public globalSwapFailure = false;

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event ExchangeRateSet(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 rate
    );
    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        // Set up some default exchange rates (scaled by 1e18)
        // 1 USDC = 1 USDC (1:1)
        setExchangeRate(address(0), address(0), 1e18);
    }

    /*//////////////////////////////////////////////////////////////
                               SWAP FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable override returns (uint256 amountOut) {
        require(params.amountIn > 0, "MockRouter: Amount must be > 0");
        require(
            params.deadline >= block.timestamp,
            "MockRouter: Deadline exceeded"
        );

        // Check if swap should fail for testing
        if (globalSwapFailure || shouldFailSwap[params.tokenIn]) {
            revert("MockRouter: Swap failed");
        }

        // Check if pool exists
        require(
            poolExists[params.tokenIn][params.tokenOut],
            "MockRouter: Pool does not exist"
        );

        // Get exchange rate
        uint256 rate = exchangeRates[params.tokenIn][params.tokenOut];
        require(rate > 0, "MockRouter: No exchange rate set");

        // Calculate output amount with simulated slippage
        amountOut = (params.amountIn * rate) / 1e18;

        // Apply slippage (reduce output)
        amountOut = (amountOut * (10000 - slippage)) / 10000;

        // Check minimum amount out
        require(
            amountOut >= params.amountOutMinimum,
            "MockRouter: Insufficient output amount"
        );

        // Transfer tokens
        IERC20(params.tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            params.amountIn
        );

        // Mint or transfer output tokens to recipient
        _provideOutputTokens(params.tokenOut, params.recipient, amountOut);

        emit SwapExecuted(
            params.tokenIn,
            params.tokenOut,
            params.amountIn,
            amountOut
        );
        emit SwapExecuted(
            params.tokenIn,
            params.tokenOut,
            params.recipient,
            params.amountIn,
            amountOut,
            params.fee
        );

        return amountOut;
    }

    function exactInput(
        ExactInputParams calldata params
    ) external payable override returns (uint256 amountOut) {
        // For simplicity, not implementing multi-hop swaps in mock
        revert("MockRouter: Multi-hop swaps not implemented in mock");
    }

    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable override returns (uint256 amountIn) {
        // For simplicity, not implementing exact output in mock
        revert("MockRouter: Exact output not implemented in mock");
    }

    /*//////////////////////////////////////////////////////////////
                               UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view override returns (address pool) {
        // Return a dummy pool address if pool exists
        if (poolExists[tokenA][tokenB] || poolExists[tokenB][tokenA]) {
            return
                address(
                    uint160(
                        uint256(
                            keccak256(abi.encodePacked(tokenA, tokenB, fee))
                        )
                    )
                );
        }
        return address(0);
    }

    function poolExistsView(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view override returns (bool exists) {
        return poolExists[tokenA][tokenB] || poolExists[tokenB][tokenA];
    }

    /*//////////////////////////////////////////////////////////////
                               MULTICALL SUPPORT
    //////////////////////////////////////////////////////////////*/

    function multicall(
        bytes[] calldata data
    ) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            require(success, "MockRouter: Multicall failed");
            results[i] = result;
        }
        return results;
    }

    /*//////////////////////////////////////////////////////////////
                               EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function refundETH() external payable override {
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable override {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(
            balance >= amountMinimum,
            "MockRouter: Insufficient token balance"
        );
        IERC20(token).safeTransfer(recipient, balance);
    }

    /*//////////////////////////////////////////////////////////////
                               MOCK CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Set exchange rate between two tokens
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param rate Exchange rate scaled by 1e18 (e.g., 2e18 = 2:1 ratio)
     */
    function setExchangeRate(
        address tokenIn,
        address tokenOut,
        uint256 rate
    ) public {
        exchangeRates[tokenIn][tokenOut] = rate;
        poolExists[tokenIn][tokenOut] = true;
        emit ExchangeRateSet(tokenIn, tokenOut, rate);
    }

    /**
     * @dev Set whether a specific token swap should fail
     */
    function setShouldFailSwap(address token, bool shouldFail) external {
        shouldFailSwap[token] = shouldFail;
    }

    /**
     * @dev Set global swap failure for testing
     */
    function setGlobalSwapFailure(bool shouldFail) external {
        globalSwapFailure = shouldFail;
    }

    /**
     * @dev Set simulated slippage in basis points
     */
    function setSlippage(uint256 _slippage) external {
        require(_slippage <= 1000, "MockRouter: Max 10% slippage");
        slippage = _slippage;
    }

    /**
     * @dev Provide output tokens to recipient (mint if needed)
     */
    function _provideOutputTokens(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        // Try to transfer existing tokens first
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance >= amount) {
            IERC20(token).safeTransfer(recipient, amount);
        } else {
            // If mock token, try to mint (this will fail for real tokens, which is expected)
            try IMockERC20(token).mint(recipient, amount) {
                // Successfully minted
            } catch {
                // If can't mint, transfer what we have and revert if insufficient
                if (balance > 0) {
                    IERC20(token).safeTransfer(recipient, balance);
                }
                revert("MockRouter: Insufficient token liquidity");
            }
        }
    }

    /**
     * @dev Fund the router with tokens for testing
     */
    function fundRouter(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }
}

/**
 * @dev Interface for mock tokens that support minting
 */
interface IMockERC20 {
    function mint(address to, uint256 amount) external;
}
