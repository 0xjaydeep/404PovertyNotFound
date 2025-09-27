// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title IUniswapV4Core
 * @dev Core Uniswap V4 types and structures used across interfaces
 * This provides common types needed for router and quoter interfaces
 */
interface IUniswapV4Core {
    /*//////////////////////////////////////////////////////////////
                               CORE TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Currency type for Uniswap V4
     * Can represent ETH (address(0)) or any ERC20 token
     */
    type Currency is address;

    /**
     * @dev Pool key identifying a unique pool
     */
    struct PoolKey {
        Currency currency0;    // First currency (lower address)
        Currency currency1;    // Second currency (higher address)
        uint24 fee;           // Pool fee tier
        int24 tickSpacing;    // Tick spacing for the pool
        address hooks;        // Hook contract address
    }

    /**
     * @dev Pool ID derived from PoolKey
     */
    type PoolId is bytes32;

    /**
     * @dev Balance delta representing changes in token balances
     */
    struct BalanceDelta {
        int128 amount0;  // Change in currency0 balance
        int128 amount1;  // Change in currency1 balance
    }

    /*//////////////////////////////////////////////////////////////
                               SWAP TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Parameters for a swap operation
     */
    struct SwapParams {
        bool zeroForOne;           // Direction of swap (token0 -> token1 or vice versa)
        int256 amountSpecified;    // Amount to swap (positive = exact input, negative = exact output)
        uint160 sqrtPriceLimitX96; // Price limit for the swap
    }

    /**
     * @dev Parameters for modifying liquidity
     */
    struct ModifyLiquidityParams {
        int24 tickLower;     // Lower tick of the position
        int24 tickUpper;     // Upper tick of the position
        int256 liquidityDelta; // Change in liquidity (positive = add, negative = remove)
    }

    /*//////////////////////////////////////////////////////////////
                               POSITION TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Information about a liquidity position
     */
    struct Position {
        uint128 liquidity;           // Amount of liquidity
        uint256 feeGrowthInside0LastX128; // Fee growth for token0
        uint256 feeGrowthInside1LastX128; // Fee growth for token1
        uint128 tokensOwed0;         // Tokens owed for token0
        uint128 tokensOwed1;         // Tokens owed for token1
    }

    /*//////////////////////////////////////////////////////////////
                               POOL STATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Current state of a pool
     */
    struct PoolState {
        uint160 sqrtPriceX96;        // Current price in sqrtPriceX96 format
        int24 tick;                  // Current tick
        uint24 protocolFee;          // Protocol fee for the pool
        uint24 lpFee;               // LP fee for the pool
    }

    /*//////////////////////////////////////////////////////////////
                               FEE TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Standard fee tiers
     */
    uint24 constant FEE_LOW = 500;      // 0.05%
    uint24 constant FEE_MEDIUM = 3000;  // 0.3%
    uint24 constant FEE_HIGH = 10000;   // 1.0%

    /**
     * @dev Maximum fee that can be charged
     */
    uint24 constant MAX_FEE = 1000000;  // 100%

    /*//////////////////////////////////////////////////////////////
                               TICK TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Tick spacing for different fee tiers
     */
    int24 constant TICK_SPACING_LOW = 10;     // For 0.05% fee
    int24 constant TICK_SPACING_MEDIUM = 60;  // For 0.3% fee
    int24 constant TICK_SPACING_HIGH = 200;   // For 1.0% fee

    /**
     * @dev Minimum and maximum tick values
     */
    int24 constant MIN_TICK = -887272;
    int24 constant MAX_TICK = 887272;

    /*//////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Convert Currency to address
     * @param currency The currency to convert
     * @return addr The address representation
     */
    function toAddress(Currency currency) external pure returns (address addr);

    /**
     * @dev Convert address to Currency
     * @param addr The address to convert
     * @return currency The Currency representation
     */
    function toCurrency(address addr) external pure returns (Currency currency);

    /**
     * @dev Check if currency is ETH
     * @param currency The currency to check
     * @return isETH True if currency represents ETH
     */
    function isETH(Currency currency) external pure returns (bool isETH);

    /**
     * @dev Calculate PoolId from PoolKey
     * @param key The pool key
     * @return poolId The calculated pool ID
     */
    function toId(PoolKey memory key) external pure returns (PoolId poolId);

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event PoolInitialized(
        PoolId indexed poolId,
        Currency indexed currency0,
        Currency indexed currency1,
        uint24 fee,
        int24 tickSpacing,
        address hooks
    );

    event Swap(
        PoolId indexed poolId,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    event ModifyLiquidity(
        PoolId indexed poolId,
        address indexed sender,
        int24 tickLower,
        int24 tickUpper,
        int256 liquidityDelta
    );

    /*//////////////////////////////////////////////////////////////
                               ERRORS
    //////////////////////////////////////////////////////////////*/

    error PoolNotInitialized();
    error PoolAlreadyInitialized();
    error TickLowerGreaterThanTickUpper();
    error TickLowerTooSmall();
    error TickUpperTooLarge();
    error LiquidityZero();
    error LiquidityTooLarge();
    error SwapAmountCannotBeZero();
    error InvalidFee();
    error InvalidTickSpacing();
    error InsufficientLiquidity();
    error PriceLimitAlreadyExceeded();
    error PriceLimitOutOfBounds();
}