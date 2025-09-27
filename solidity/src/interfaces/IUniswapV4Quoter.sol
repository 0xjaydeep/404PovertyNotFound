// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title IUniswapV4Quoter
 * @dev Interface for Uniswap V4 Quoter functionality
 * Used to get price quotes before executing swaps
 */
interface IUniswapV4Quoter {
    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Quote result for single-hop swap
     */
    struct QuoteExactInputSingleResult {
        uint256 amountOut;         // Amount of output tokens
        uint160 sqrtPriceX96After; // Price after the swap
        uint32 initializedTicksCrossed; // Number of ticks crossed
        uint256 gasEstimate;       // Estimated gas cost
    }

    /**
     * @dev Quote result for multi-hop swap
     */
    struct QuoteExactInputResult {
        uint256 amountOut;         // Amount of output tokens
        uint160[] sqrtPriceX96AfterList; // Prices after each hop
        uint32[] initializedTicksCrossedList; // Ticks crossed for each hop
        uint256 gasEstimate;       // Estimated gas cost
    }

    /**
     * @dev Quote result for exact output swap
     */
    struct QuoteExactOutputSingleResult {
        uint256 amountIn;          // Amount of input tokens needed
        uint160 sqrtPriceX96After; // Price after the swap
        uint32 initializedTicksCrossed; // Number of ticks crossed
        uint256 gasEstimate;       // Estimated gas cost
    }

    /*//////////////////////////////////////////////////////////////
                               QUOTE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the amount out received for a given exact input swap without executing the swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param fee Pool fee tier
     * @param amountIn Amount of input tokens
     * @param sqrtPriceLimitX96 Price limit (0 = no limit)
     * @return result Quote result with amount out and swap details
     */
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (QuoteExactInputSingleResult memory result);

    /**
     * @dev Returns the amount out received for a given exact input multi-hop swap
     * @param path Encoded path of tokens and fees
     * @param amountIn Amount of input tokens
     * @return result Quote result with amount out and swap details
     */
    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    ) external returns (QuoteExactInputResult memory result);

    /**
     * @dev Returns the amount in required for a given exact output swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param fee Pool fee tier
     * @param amountOut Desired amount of output tokens
     * @param sqrtPriceLimitX96 Price limit (0 = no limit)
     * @return result Quote result with amount in and swap details
     */
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (QuoteExactOutputSingleResult memory result);

    /*//////////////////////////////////////////////////////////////
                               PRICE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get current price for a token pair
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param fee Pool fee tier
     * @return sqrtPriceX96 Current price in sqrtPriceX96 format
     * @return tick Current tick
     */
    function getPoolPrice(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (uint160 sqrtPriceX96, int24 tick);

    /**
     * @dev Convert amount of tokenA to equivalent amount of tokenB at current price
     * @param tokenA Input token address
     * @param tokenB Output token address
     * @param fee Pool fee tier
     * @param amountA Amount of tokenA
     * @return amountB Equivalent amount of tokenB
     */
    function convertAmountAtCurrentPrice(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint256 amountA
    ) external view returns (uint256 amountB);

    /*//////////////////////////////////////////////////////////////
                               UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get pool liquidity information
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param fee Pool fee tier
     * @return liquidity Current pool liquidity
     * @return sqrtPriceX96 Current price
     * @return tick Current tick
     */
    function getPoolState(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (
        uint128 liquidity,
        uint160 sqrtPriceX96,
        int24 tick
    );

    /**
     * @dev Check if sufficient liquidity exists for a swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param fee Pool fee tier
     * @param amountIn Amount of input tokens
     * @return hasSufficientLiquidity True if swap is possible
     * @return estimatedAmountOut Estimated output amount
     */
    function checkLiquidity(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) external view returns (
        bool hasSufficientLiquidity,
        uint256 estimatedAmountOut
    );

    /*//////////////////////////////////////////////////////////////
                               BATCH QUOTES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get quotes for multiple swaps in a single call
     * @param tokenIns Array of input token addresses
     * @param tokenOuts Array of output token addresses
     * @param fees Array of pool fee tiers
     * @param amountsIn Array of input amounts
     * @return amountsOut Array of output amounts
     * @return gasEstimates Array of gas estimates
     */
    function batchQuoteExactInputSingle(
        address[] calldata tokenIns,
        address[] calldata tokenOuts,
        uint24[] calldata fees,
        uint256[] calldata amountsIn
    ) external returns (
        uint256[] memory amountsOut,
        uint256[] memory gasEstimates
    );

    /*//////////////////////////////////////////////////////////////
                               SLIPPAGE HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Calculate minimum amount out with slippage tolerance
     * @param amountOut Quoted amount out
     * @param slippageToleranceBps Slippage tolerance in basis points
     * @return minAmountOut Minimum amount out accounting for slippage
     */
    function calculateMinAmountOut(
        uint256 amountOut,
        uint256 slippageToleranceBps
    ) external pure returns (uint256 minAmountOut);

    /**
     * @dev Calculate maximum amount in with slippage tolerance
     * @param amountIn Quoted amount in
     * @param slippageToleranceBps Slippage tolerance in basis points
     * @return maxAmountIn Maximum amount in accounting for slippage
     */
    function calculateMaxAmountIn(
        uint256 amountIn,
        uint256 slippageToleranceBps
    ) external pure returns (uint256 maxAmountIn);

    /*//////////////////////////////////////////////////////////////
                               FEE CALCULATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Estimate total fees for a swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param fee Pool fee tier
     * @param amountIn Amount of input tokens
     * @return protocolFee Protocol fee amount
     * @return poolFee Pool fee amount
     * @return totalFee Total fee amount
     */
    function estimateSwapFees(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) external view returns (
        uint256 protocolFee,
        uint256 poolFee,
        uint256 totalFee
    );
}