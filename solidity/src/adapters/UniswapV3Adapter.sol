// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interfaces/IUniswapV4Router.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// V3 Router interface (moved outside contract)
interface ISwapRouter {
        struct ExactInputSingleParams {
            address tokenIn;
            address tokenOut;
            uint24 fee;
            address recipient;
            uint256 deadline;
            uint256 amountIn;
            uint256 amountOutMinimum;
            uint160 sqrtPriceLimitX96;
        }

        function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

/**
 * @title UniswapV3Adapter
 * @dev Adapter to use Uniswap V3 router with V4 interface for hackathon
 * Uses real Uniswap V3 SwapRouter for actual DEX functionality
 */
contract UniswapV3Adapter is IUniswapV4Router {
    using SafeERC20 for IERC20;

    // Uniswap V3 Router address (mainnet/testnet)
    address public constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    ISwapRouter public immutable swapRouter;

    constructor() {
        swapRouter = ISwapRouter(UNISWAP_V3_ROUTER);
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountOut)
    {
        // Convert V4 params to V3 params
        ISwapRouter.ExactInputSingleParams memory v3Params = ISwapRouter.ExactInputSingleParams({
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            fee: params.fee,
            recipient: params.recipient,
            deadline: params.deadline,
            amountIn: params.amountIn,
            amountOutMinimum: params.amountOutMinimum,
            sqrtPriceLimitX96: params.sqrtPriceLimitX96
        });

        // Transfer tokens to this contract first
        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);

        // Approve V3 router
        IERC20(params.tokenIn).approve(UNISWAP_V3_ROUTER, params.amountIn);

        // Execute swap through V3 router
        return swapRouter.exactInputSingle(v3Params);
    }

    // Stub implementations
    function exactInput(ExactInputParams calldata) external payable override returns (uint256) {
        revert("Use V3 router directly for multi-hop");
    }

    function exactOutputSingle(ExactOutputSingleParams calldata) external payable override returns (uint256) {
        revert("Use V3 router directly for exact output");
    }

    function getPool(address tokenA, address tokenB, uint24 fee) external view override returns (address pool) {
        // V3 pool address calculation (for reference)
        return address(0); // Would need V3 factory for real implementation
    }

    function poolExistsView(address, address, uint24) external pure override returns (bool) {
        return true; // Assume pools exist on V3
    }

    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        // Could delegate to V3 router's multicall
        revert("Use V3 router multicall directly");
    }

    function refundETH() external payable override {
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable override {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= amountMinimum, "Insufficient token balance");
        IERC20(token).safeTransfer(recipient, balance);
    }
}