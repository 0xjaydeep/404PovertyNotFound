// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title IUniswapV4Router
 * @dev Interface for Uniswap V4 Router functionality
 * Simplified interface focused on exact input swaps for investment use case
 */
interface IUniswapV4Router {
    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Parameters for exact input single-hop swap
     */
    struct ExactInputSingleParams {
        address tokenIn;           // Input token address
        address tokenOut;          // Output token address
        uint24 fee;               // Fee tier (e.g., 3000 = 0.3%)
        address recipient;         // Address to receive output tokens
        uint256 deadline;          // Transaction deadline
        uint256 amountIn;         // Exact amount of input tokens
        uint256 amountOutMinimum; // Minimum amount of output tokens
        uint160 sqrtPriceLimitX96; // Price limit (0 = no limit)
    }

    /**
     * @dev Parameters for exact input multi-hop swap
     */
    struct ExactInputParams {
        bytes path;               // Encoded path of tokens and fees
        address recipient;        // Address to receive output tokens
        uint256 deadline;         // Transaction deadline
        uint256 amountIn;        // Exact amount of input tokens
        uint256 amountOutMinimum; // Minimum amount of output tokens
    }

    /**
     * @dev Parameters for exact output single-hop swap
     */
    struct ExactOutputSingleParams {
        address tokenIn;           // Input token address
        address tokenOut;          // Output token address
        uint24 fee;               // Fee tier
        address recipient;         // Address to receive output tokens
        uint256 deadline;          // Transaction deadline
        uint256 amountOut;        // Exact amount of output tokens desired
        uint256 amountInMaximum;  // Maximum amount of input tokens
        uint160 sqrtPriceLimitX96; // Price limit
    }

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed recipient,
        uint256 amountIn,
        uint256 amountOut,
        uint24 fee
    );

    /*//////////////////////////////////////////////////////////////
                               SWAP FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Swaps `amountIn` of one token for as much as possible of another token
     * @param params The parameters necessary for the swap
     * @return amountOut The amount of the received token
     */
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    /**
     * @dev Swaps `amountIn` of one token for as much as possible of another along the specified path
     * @param params The parameters necessary for the multi-hop swap
     * @return amountOut The amount of the received token
     */
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    /**
     * @dev Swaps as little as possible of one token for `amountOut` of another token
     * @param params The parameters necessary for the swap
     * @return amountIn The amount of the input token
     */
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    /*//////////////////////////////////////////////////////////////
                               UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the pool address for the given tokens and fee
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param fee Pool fee tier
     * @return pool Pool address
     */
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /**
     * @dev Checks if a pool exists for the given tokens and fee
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param fee Pool fee tier
     * @return exists True if pool exists
     */
    function poolExistsView(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (bool exists);

    /*//////////////////////////////////////////////////////////////
                               MULTICALL SUPPORT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Call multiple functions in a single transaction
     * @param data Array of encoded function calls
     * @return results Array of return data from each call
     */
    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);

    /*//////////////////////////////////////////////////////////////
                               EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Refund ETH to the sender
     */
    function refundETH() external payable;

    /**
     * @dev Sweep tokens to the sender
     * @param token Token address to sweep
     * @param amountMinimum Minimum amount to sweep
     * @param recipient Address to receive tokens
     */
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}