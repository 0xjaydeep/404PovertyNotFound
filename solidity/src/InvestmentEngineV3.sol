// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IPlanManager.sol";
import "./interfaces/IUniswapV4Router.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title InvestmentEngineV3Simple
 * @dev Simple DEX-Integrated Investment Engine for Hackathon MVP
 *
 * Core functionality:
 * - depositAndInvest(): One transaction creates diversified portfolio
 * - Direct token delivery to users (no custody)
 * - Instant execution via Uniswap V4
 */
contract InvestmentEngineV3Simple {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public planManager;
    IUniswapV4Router public router;
    address public baseToken; // USDC
    uint24 public fee = 3000; // 0.3%
    uint256 public slippage = 500; // 5%

    uint256 private _investmentCounter;
    mapping(uint256 => Investment) public investments;

    /*//////////////////////////////////////////////////////////////
                               STRUCTS & EVENTS
    //////////////////////////////////////////////////////////////*/

    struct Investment {
        address user;
        uint256 planId;
        uint256 amount;
        uint256 timestamp;
    }

    event InvestmentExecuted(
        uint256 indexed investmentId,
        address indexed user,
        uint256 indexed planId,
        uint256 amount
    );

    event TokenSwapped(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _planManager,
        address _router,
        address _baseToken
    ) {
        owner = msg.sender;
        planManager = _planManager;
        router = IUniswapV4Router(_router);
        baseToken = _baseToken;
    }

    /*//////////////////////////////////////////////////////////////
                               CORE FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Deposit base tokens and instantly create diversified portfolio
     * @param amount Amount of base tokens to invest
     * @param planId Investment plan ID
     * @return investmentId Investment identifier
     */
    function depositAndInvest(
        uint256 amount,
        uint256 planId
    ) external returns (uint256 investmentId) {
        require(amount > 0, "Amount must be > 0");

        // Get plan details
        IPlanManager.InvestmentPlan memory plan = IPlanManager(planManager).getPlan(planId);
        require(plan.isActive, "Plan not active");

        // Transfer base tokens from user
        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), amount);

        // Create investment record
        _investmentCounter++;
        investmentId = _investmentCounter;
        investments[investmentId] = Investment({
            user: msg.sender,
            planId: planId,
            amount: amount,
            timestamp: block.timestamp
        });

        // Execute swaps for each allocation
        for (uint256 i = 0; i < plan.allocations.length; i++) {
            IPlanManager.AssetAllocation memory allocation = plan.allocations[i];
            uint256 allocationAmount = (amount * allocation.targetPercentage) / 10000;

            if (allocationAmount > 0) {
                if (allocation.tokenAddress == baseToken) {
                    // Direct transfer for base token
                    IERC20(baseToken).safeTransfer(msg.sender, allocationAmount);
                } else {
                    // Swap via Uniswap V4
                    _swapToken(allocation.tokenAddress, allocationAmount);
                }
            }
        }

        emit InvestmentExecuted(investmentId, msg.sender, planId, amount);
        return investmentId;
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Execute token swap via Uniswap V4
     * @param tokenOut Output token address
     * @param amountIn Input amount in base token
     */
    function _swapToken(address tokenOut, uint256 amountIn) internal {
        // Calculate minimum output with slippage protection
        uint256 minAmountOut = (amountIn * (10000 - slippage)) / 10000;

        // Approve router
        IERC20(baseToken).approve(address(router), amountIn);

        // Prepare swap params
        IUniswapV4Router.ExactInputSingleParams memory params = IUniswapV4Router
            .ExactInputSingleParams({
                tokenIn: baseToken,
                tokenOut: tokenOut,
                fee: fee,
                recipient: msg.sender, // Direct to user
                deadline: block.timestamp + 300, // 5 min
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });

        // Execute swap
        try router.exactInputSingle(params) returns (uint256 amountOut) {
            emit TokenSwapped(msg.sender, baseToken, tokenOut, amountIn, amountOut);
        } catch {
            // On failure, send base tokens to user
            IERC20(baseToken).safeTransfer(msg.sender, amountIn);
        }
    }

    /*//////////////////////////////////////////////////////////////
                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getInvestment(uint256 investmentId) external view returns (Investment memory) {
        return investments[investmentId];
    }

    function getTotalInvestments() external view returns (uint256) {
        return _investmentCounter;
    }

    /*//////////////////////////////////////////////////////////////
                               ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setPlanManager(address _planManager) external {
        require(msg.sender == owner, "Only owner");
        planManager = _planManager;
    }

    function setRouter(address _router) external {
        require(msg.sender == owner, "Only owner");
        router = IUniswapV4Router(_router);
    }

    function setSlippage(uint256 _slippage) external {
        require(msg.sender == owner, "Only owner");
        require(_slippage <= 2000, "Max 20%");
        slippage = _slippage;
    }

    function rescueTokens(address token, uint256 amount) external {
        require(msg.sender == owner, "Only owner");
        IERC20(token).safeTransfer(owner, amount);
    }
}