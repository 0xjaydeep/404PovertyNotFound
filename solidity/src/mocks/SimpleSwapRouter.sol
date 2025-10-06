// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interfaces/IUniswapV4Router.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SimpleSwapRouter
 * @dev Ultra-simple router mock for hackathon demos
 * Fixed 1:1 swap rates, instant execution, no slippage
 */
contract SimpleSwapRouter is IUniswapV4Router {
    using SafeERC20 for IERC20;

    // Simple 1:1 swap for all tokens
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountOut)
    {
        // Transfer input tokens
        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);

        // For demo: 1:1 swap (adjust decimals if needed)
        amountOut = params.amountIn;

        // Try to mint output tokens (works with MockERC20)
        try IMockToken(params.tokenOut).mint(params.recipient, amountOut) {
            // Success
        } catch {
            // Fallback: just return input amount as if swapped
            IERC20(params.tokenIn).safeTransfer(params.recipient, params.amountIn);
            amountOut = params.amountIn;
        }

        return amountOut;
    }

    // Stub implementations for interface compliance
    function exactInput(ExactInputParams calldata) external payable override returns (uint256) {
        revert("Not implemented in simple mock");
    }

    function exactOutputSingle(ExactOutputSingleParams calldata) external payable override returns (uint256) {
        revert("Not implemented in simple mock");
    }

    function getPool(address, address, uint24) external pure override returns (address) {
        return address(0x1); // Dummy pool address
    }

    function poolExistsView(address, address, uint24) external pure override returns (bool) {
        return true; // All pools "exist"
    }

    function multicall(bytes[] calldata) external payable override returns (bytes[] memory) {
        revert("Not implemented in simple mock");
    }

    function refundETH() external payable override {}
    function sweepToken(address, uint256, address) external payable override {}
}

interface IMockToken {
    function mint(address to, uint256 amount) external;
}