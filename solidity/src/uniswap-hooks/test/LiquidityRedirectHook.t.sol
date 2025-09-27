// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test";

// V4 Core & Periphery Imports
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";

// Test Utilities
import {Deployers} from "./utils/Deployers.sol";
import {EasyPosm} from "./utils/libraries/EasyPosm.sol";

// The contract we're testing
import {LiquidityRedirectHook} from "../src/LiquidityRedirectHook.sol";

contract LiquidityRedirectHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using EasyPosm for IPositionManager;

    // --- State for the pools and hook ---
    LiquidityRedirectHook hook;

    // The pool where investments are sent
    PoolKey targetPoolKey;
    PoolId targetPoolId;

    // The pool that uses the hook
    PoolKey homePoolKey;
    PoolId homePoolId;

    function setUp() public {
        // 1. DEPLOY CORE UNISWAP ARTIFACTS
        deployArtifacts();

        // 2. SETUP THE TARGET POOL (poolAB)
        // This is the pool our hook will invest in. It has no hook itself.
        (
            Currency targetCurrency0,
            Currency targetCurrency1
        ) = deployCurrencyPair();
        targetPoolKey = PoolKey(
            targetCurrency0,
            targetCurrency1,
            3000,
            60,
            IHooks(address(0))
        );
        targetPoolId = targetPoolKey.toId();
        poolManager.initialize(targetPoolKey, Constants.SQRT_PRICE_1_1);

        // 3. DEPLOY THE HOOK
        // Configure it to use the target pool we just created.
        uint160 flags = uint160(
            Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.AFTER_SWAP_FLAG
        );
        bytes memory constructorArgs = abi.encode(
            poolManager,
            positionManager,
            targetPoolKey
        );

        // Use `deployCodeTo` for deterministic test addresses
        address hookAddress = address(uint160(flags));
        deployCodeTo(
            "LiquidityRedirectHook.sol:LiquidityRedirectHook",
            constructorArgs,
            hookAddress
        );
        hook = LiquidityRedirectHook(payable(hookAddress));

        // 4. SETUP THE HOME POOL (pool1)
        // This is the pool users interact with, which triggers the hook.
        (Currency homeCurrency0, Currency homeCurrency1) = deployCurrencyPair();
        homePoolKey = PoolKey(
            homeCurrency0,
            homeCurrency1,
            3000,
            60,
            IHooks(hook)
        );
        homePoolId = homePoolKey.toId();
        poolManager.initialize(homePoolKey, Constants.SQRT_PRICE_1_1);

        // 5. ADD INITIAL LIQUIDITY TO THE HOME POOL
        // This provides capital for swaps and also triggers the hook for the first time.
        positionManager.mint(
            homePoolKey,
            TickMath.minUsableTick(60),
            TickMath.maxUsableTick(60),
            100 ether,
            type(uint256).max,
            type(uint256).max,
            address(this),
            block.timestamp,
            Constants.ZERO_BYTES
        );
    }

    /// @notice Test that swapping in the home pool redirects fee liquidity to the target pool.
    function test_SwapRedirectsLiquidity() public {
        // --- ARRANGE ---
        // Get the hook's liquidity in the target pool *before* the swap.
        // It will be > 0 because of the initial liquidity added in setUp().
        uint256 liquidityBefore = poolManager.getLiquidity(
            targetPoolId,
            address(hook),
            -887220,
            887220
        );
        assertTrue(
            liquidityBefore > 0,
            "Hook should have initial liquidity from setUp"
        );

        // --- ACT ---
        // Perform a swap on the *home pool*. This generates fees that the hook will invest.
        swapRouter.swapExactTokensForTokens({
            amountIn: 1 ether,
            amountOutMin: 0,
            zeroForOne: true,
            poolKey: homePoolKey,
            hookData: Constants.ZERO_BYTES,
            receiver: address(this),
            deadline: block.timestamp
        });

        // --- ASSERT ---
        // Check that the hook's liquidity in the *target pool* has increased.
        uint256 liquidityAfter = poolManager.getLiquidity(
            targetPoolId,
            address(hook),
            -887220,
            887220
        );
        assertGt(
            liquidityAfter,
            liquidityBefore,
            "Hook liquidity in target pool should increase after swap"
        );
    }

    /// @notice Test that adding liquidity to the home pool also redirects fee liquidity.
    function test_AddLiquidityRedirectsLiquidity() public {
        // --- ARRANGE ---
        // Get the hook's liquidity in the target pool *before* the action.
        uint256 liquidityBefore = poolManager.getLiquidity(
            targetPoolId,
            address(hook),
            -887220,
            887220
        );
        assertTrue(
            liquidityBefore > 0,
            "Hook should have initial liquidity from setUp"
        );

        // --- ACT ---
        // Add more liquidity to the *home pool*.
        positionManager.mint(
            homePoolKey,
            TickMath.minUsableTick(60),
            TickMath.maxUsableTick(60),
            50 ether, // Add another 50 ETH worth of liquidity
            type(uint256).max,
            type(uint256).max,
            address(this),
            block.timestamp,
            Constants.ZERO_BYTES
        );

        // --- ASSERT ---
        // Check that the hook's liquidity in the *target pool* has increased.
        uint256 liquidityAfter = poolManager.getLiquidity(
            targetPoolId,
            address(hook),
            -887220,
            887220
        );
        assertGt(
            liquidityAfter,
            liquidityBefore,
            "Hook liquidity in target pool should increase after adding more liquidity"
        );
    }
}
