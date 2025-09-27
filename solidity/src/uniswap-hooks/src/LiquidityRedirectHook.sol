// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager, SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
//
import {IPositionManager} from "@uniswap-hooks/v4-core/src/interfaces/IPositionManager.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";

contract LiquidityRedirectHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // NOTE: ---------------------------------------------------------
    // state variables should typically be unique to a pool
    // a single hook contract should be able to service multiple pools
    // ---------------------------------------------------------------

    // --- NEW STATE VARIABLES ---
    IPositionManager public immutable positionManager;
    PoolKey public immutable targetPool;

    // --- UPDATED CONSTRUCTOR ---
    constructor(
        IPoolManager _poolManager,
        IPositionManager _positionManager,
        PoolKey memory _targetPool
    ) BaseHook(_poolManager) {
        positionManager = _positionManager;
        targetPool = _targetPool;
    }

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    // -----------------------------------------------
    // NOTE: see IHooks.sol for function documentation
    // -----------------------------------------------

    // Note: afterAddLiquidity receives a BalanceDelta as well since v4.2.0
    function _afterAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4) {
        // We can reuse the same logic as afterSwap
        _invest(delta);
        return BaseHook.afterAddLiquidity.selector;
    }

    function _afterSwap(
        address,
        PoolKey calldata,
        SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        _invest(delta);
        return (BaseHook.afterSwap.selector, 0);
    }

    function _invest(BalanceDelta delta) private {
        // Get the amount of tokens this hook contract received from the transaction
        int256 d0 = delta.amount0();
        int256 d1 = delta.amount1();

        // Only proceed if the hook has received a positive amount of at least one token
        if (d0 <= 0 && d1 <= 0) return;

        uint128 amount0 = d0 > 0 ? uint128(d0) / 2 : 0; // Use 50% of what was received
        uint128 amount1 = d1 > 0 ? uint128(d1) / 2 : 0;

        // Get the current price of the *target* pool to create an appropriate liquidity range
        (uint160 sqrtPriceX96, , , ) = poolManager.getSlot0(targetPool.toId());
        int24 currentTick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);

        // Define a range around the current price that's wide enough to accommodate price movement
        int24 tickSpacing = targetPool.tickSpacing;
        // Use a wider range (±50 ticks) for more stable pools like ETH/WBTC
        int24 tickLower = ((currentTick - 50 * tickSpacing) / tickSpacing) *
            tickSpacing;
        int24 tickUpper = ((currentTick + 50 * tickSpacing) / tickSpacing) *
            tickSpacing;

        // Convert our token amounts into a liquidity amount for the target pool
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            amount0,
            amount1
        );

        if (liquidity == 0) return;

        // To add liquidity, we must first "settle" the tokens from the PoolManager's
        // balance to this contract, then call the PositionManager.
        // The `lock` function is the idiomatic way to do this from within a hook.
        bytes memory actions = abi.encodePacked(
            uint8(Actions.SETTLE_PAIR),
            uint8(Actions.MINT_POSITION)
        );

        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(targetPool.currency0, targetPool.currency1);
        params[1] = abi.encode(
            targetPool,
            tickLower,
            tickUpper,
            liquidity,
            0,
            0,
            address(this),
            bytes("")
        );

        positionManager.modifyLiquidities(
            abi.encode(actions, params),
            block.timestamp
        );
    }
}
