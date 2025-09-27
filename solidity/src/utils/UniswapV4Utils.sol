// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interfaces/IUniswapV4Core.sol";

/**
 * @title UniswapV4Utils
 * @dev Utility library for Uniswap V4 operations
 * Provides helper functions for common operations and calculations
 */
library UniswapV4Utils {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @dev Used for price calculations
    uint256 internal constant Q96 = 2**96;

    /*//////////////////////////////////////////////////////////////
                               POOL KEY UTILITIES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Create a pool key for the given parameters
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param fee Pool fee tier
     * @param hooks Hook contract address
     * @return key The pool key
     */
    function createPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee,
        address hooks
    ) internal pure returns (IUniswapV4Core.PoolKey memory key) {
        // Ensure tokens are ordered correctly (token0 < token1)
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        // Determine tick spacing based on fee
        int24 tickSpacing = getTickSpacing(fee);

        key = IUniswapV4Core.PoolKey({
            currency0: IUniswapV4Core.Currency.wrap(tokenA),
            currency1: IUniswapV4Core.Currency.wrap(tokenB),
            fee: fee,
            tickSpacing: tickSpacing,
            hooks: hooks
        });
    }

    /**
     * @dev Get the appropriate tick spacing for a fee tier
     * @param fee The fee tier
     * @return tickSpacing The tick spacing
     */
    function getTickSpacing(uint24 fee) internal pure returns (int24 tickSpacing) {
        if (fee == IUniswapV4Core.FEE_LOW) {
            return IUniswapV4Core.TICK_SPACING_LOW;
        } else if (fee == IUniswapV4Core.FEE_MEDIUM) {
            return IUniswapV4Core.TICK_SPACING_MEDIUM;
        } else if (fee == IUniswapV4Core.FEE_HIGH) {
            return IUniswapV4Core.TICK_SPACING_HIGH;
        } else {
            // For custom fees, use medium spacing as default
            return IUniswapV4Core.TICK_SPACING_MEDIUM;
        }
    }

    /*//////////////////////////////////////////////////////////////
                               PRICE CALCULATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Calculate the amount of token1 equivalent to a given amount of token0
     * @param amount0 Amount of token0
     * @param sqrtPriceX96 Current price in sqrtPriceX96 format
     * @return amount1 Equivalent amount of token1
     */
    function getAmount1ForAmount0(
        uint256 amount0,
        uint160 sqrtPriceX96
    ) internal pure returns (uint256 amount1) {
        // amount1 = amount0 * (sqrtPriceX96 / 2^96)^2
        uint256 priceX96 = uint256(sqrtPriceX96) ** 2;
        amount1 = (amount0 * priceX96) / (Q96 ** 2);
    }

    /**
     * @dev Calculate the amount of token0 equivalent to a given amount of token1
     * @param amount1 Amount of token1
     * @param sqrtPriceX96 Current price in sqrtPriceX96 format
     * @return amount0 Equivalent amount of token0
     */
    function getAmount0ForAmount1(
        uint256 amount1,
        uint160 sqrtPriceX96
    ) internal pure returns (uint256 amount0) {
        // amount0 = amount1 / (sqrtPriceX96 / 2^96)^2
        uint256 priceX96 = uint256(sqrtPriceX96) ** 2;
        amount0 = (amount1 * (Q96 ** 2)) / priceX96;
    }

    /*//////////////////////////////////////////////////////////////
                               SLIPPAGE CALCULATIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Calculate minimum amount out considering slippage
     * @param amountOut Quoted amount out
     * @param slippageToleranceBps Slippage tolerance in basis points (e.g., 500 = 5%)
     * @return minAmountOut Minimum amount out
     */
    function calculateMinAmountOut(
        uint256 amountOut,
        uint256 slippageToleranceBps
    ) internal pure returns (uint256 minAmountOut) {
        require(slippageToleranceBps <= 10000, "Slippage tolerance too high");
        minAmountOut = (amountOut * (10000 - slippageToleranceBps)) / 10000;
    }

    /**
     * @dev Calculate maximum amount in considering slippage
     * @param amountIn Quoted amount in
     * @param slippageToleranceBps Slippage tolerance in basis points
     * @return maxAmountIn Maximum amount in
     */
    function calculateMaxAmountIn(
        uint256 amountIn,
        uint256 slippageToleranceBps
    ) internal pure returns (uint256 maxAmountIn) {
        require(slippageToleranceBps <= 10000, "Slippage tolerance too high");
        maxAmountIn = (amountIn * (10000 + slippageToleranceBps)) / 10000;
    }

    /*//////////////////////////////////////////////////////////////
                               VALIDATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Validate that a fee tier is supported
     * @param fee The fee tier to validate
     * @return isValid True if the fee is valid
     */
    function isValidFee(uint24 fee) internal pure returns (bool isValid) {
        return fee == IUniswapV4Core.FEE_LOW ||
               fee == IUniswapV4Core.FEE_MEDIUM ||
               fee == IUniswapV4Core.FEE_HIGH ||
               (fee <= IUniswapV4Core.MAX_FEE && fee > 0);
    }

    /**
     * @dev Validate tick range
     * @param tickLower Lower tick
     * @param tickUpper Upper tick
     * @param tickSpacing Tick spacing for the pool
     * @return isValid True if the tick range is valid
     */
    function isValidTickRange(
        int24 tickLower,
        int24 tickUpper,
        int24 tickSpacing
    ) internal pure returns (bool isValid) {
        return tickLower < tickUpper &&
               tickLower >= IUniswapV4Core.MIN_TICK &&
               tickUpper <= IUniswapV4Core.MAX_TICK &&
               tickLower % tickSpacing == 0 &&
               tickUpper % tickSpacing == 0;
    }

    /**
     * @dev Validate sqrt price
     * @param sqrtPriceX96 Price in sqrtPriceX96 format
     * @return isValid True if the price is valid
     */
    function isValidSqrtPrice(uint160 sqrtPriceX96) internal pure returns (bool isValid) {
        return sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 <= MAX_SQRT_RATIO;
    }

    /*//////////////////////////////////////////////////////////////
                               PATH ENCODING
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Encode a path for multi-hop swaps
     * @param tokens Array of token addresses
     * @param fees Array of fees for each hop
     * @return path Encoded path
     */
    function encodePath(
        address[] memory tokens,
        uint24[] memory fees
    ) internal pure returns (bytes memory path) {
        require(tokens.length >= 2, "Path must have at least 2 tokens");
        require(fees.length == tokens.length - 1, "Invalid fees array length");

        path = abi.encodePacked(tokens[0]);
        for (uint256 i = 0; i < fees.length; i++) {
            path = abi.encodePacked(path, fees[i], tokens[i + 1]);
        }
    }

    /**
     * @dev Decode the first pool from a path
     * @param path Encoded path
     * @return tokenA First token address
     * @return tokenB Second token address
     * @return fee Pool fee
     */
    function decodeFirstPool(
        bytes memory path
    ) internal pure returns (address tokenA, address tokenB, uint24 fee) {
        require(path.length >= 43, "Path too short"); // 20 + 3 + 20 = 43

        assembly {
            tokenA := div(mload(add(path, 32)), 0x1000000000000000000000000)
            fee := and(mload(add(path, 35)), 0xffffff)
            tokenB := div(mload(add(path, 55)), 0x1000000000000000000000000)
        }
    }

    /*//////////////////////////////////////////////////////////////
                               DEADLINE HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Create a deadline timestamp
     * @param secondsFromNow Seconds from current time
     * @return deadline Deadline timestamp
     */
    function createDeadline(uint256 secondsFromNow) internal view returns (uint256 deadline) {
        deadline = block.timestamp + secondsFromNow;
    }

    /**
     * @dev Validate that deadline has not passed
     * @param deadline Deadline timestamp
     */
    function checkDeadline(uint256 deadline) internal view {
        require(block.timestamp <= deadline, "Transaction deadline exceeded");
    }

    /*//////////////////////////////////////////////////////////////
                               ERROR HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get a human-readable error message for common failures
     * @param errorData Raw error data
     * @return errorMessage Human-readable error message
     */
    function parseError(bytes memory errorData) internal pure returns (string memory errorMessage) {
        if (errorData.length == 0) {
            return "Unknown error";
        }

        // Try to decode common errors
        if (errorData.length >= 4) {
            bytes4 selector = bytes4(errorData);

            if (selector == IUniswapV4Core.PoolNotInitialized.selector) {
                return "Pool not initialized";
            } else if (selector == IUniswapV4Core.InsufficientLiquidity.selector) {
                return "Insufficient liquidity";
            } else if (selector == IUniswapV4Core.SwapAmountCannotBeZero.selector) {
                return "Swap amount cannot be zero";
            } else if (selector == IUniswapV4Core.PriceLimitAlreadyExceeded.selector) {
                return "Price limit already exceeded";
            }
        }

        return "Swap failed";
    }
}