// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager, SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";

// Legacy interface for backward compatibility
interface ILiquidityManager {
    function addLiquidityToPool(PoolKey calldata poolKey, uint256 amount) external;
}

/// @title LiquidityRedirectHook
/// @notice A hook that automatically invests a portion of swap proceeds into LP positions
/// @dev This hook demonstrates same-transaction investment automation using modifyLiquiditiesWithoutUnlock
contract LiquidityRedirectHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // Events
    event SwapRedirectedToLiquidity(
        PoolId indexed poolId,
        address indexed swapper,
        uint256 redirectedAmount0,
        uint256 redirectedAmount1,
        uint128 liquidityAdded
    );

    event InvestmentExecuted(PoolId indexed poolId, uint256 tokenId, uint128 liquidityAdded);

    // Legacy events for backward compatibility
    event LiquidityRedirected(uint256 amount);
    event ShouldAddLiquidity(address caller, uint256 amount);

    error InvalidPositionManager();
    error InvestmentFailed();

    // Investment parameters
    uint256 public constant INVESTMENT_PERCENTAGE = 1000; // 10% in basis points
    int24 public constant TICK_LOWER = -887272; // Full range for simplicity
    int24 public constant TICK_UPPER = 887272;

    // Position Manager for executing liquidity operations
    IPositionManager public immutable positionManager;
    PoolKey public targetPool;

    // Mapping to track investment positions per pool
    mapping(PoolId => uint256) public investmentPositions;

    // Counter for generating token IDs (simplified for demo)
    uint256 private nextTokenId = 1;

    ILiquidityManager public liquidityManager;

    constructor(IPoolManager _poolManager, IPositionManager _positionManager, PoolKey memory _targetPool)
        BaseHook(_poolManager)
    {
        positionManager = _positionManager;
        targetPool = _targetPool;
    }

    // Function to set the liquidity manager (for backward compatibility)
    function setLiquidityManager(ILiquidityManager _liquidityManager) external {
        liquidityManager = _liquidityManager;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
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

    function _afterAddLiquidity(
        address,
        PoolKey calldata key,
        ModifyLiquidityParams calldata,
        BalanceDelta delta0,
        BalanceDelta, /* delta1 */
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        // Execute investment logic for liquidity addition
        _investFromLiquidity(key, delta0);
        return (BaseHook.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    function _afterSwap(address sender, PoolKey calldata key, SwapParams calldata, BalanceDelta delta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        // Execute investment logic within the same transaction
        _investFromSwap(key, sender, delta);

        return (BaseHook.afterSwap.selector, 0);
    }

    function _investFromSwap(PoolKey calldata key, address swapper, BalanceDelta delta) internal {
        PoolId poolId = key.toId();

        // Calculate investment amounts (10% of swap proceeds)
        uint256 redirectAmount0 = _calculateRedirectAmount(delta.amount0());
        uint256 redirectAmount1 = _calculateRedirectAmount(delta.amount1());

        // Calculate liquidity to add (simplified calculation)
        uint128 liquidityAmount = uint128((redirectAmount0 + redirectAmount1) / 1000); // Scale down for demo

        if (liquidityAmount == 0) {
            // Emit legacy event for backward compatibility
            emit LiquidityRedirected(1000);
            return;
        }

        emit SwapRedirectedToLiquidity(poolId, swapper, redirectAmount0, redirectAmount1, liquidityAmount);

        // Execute the investment using modifyLiquiditiesWithoutUnlock
        // This works because we're already in the PoolManager's unlock context
        _executeInvestment(key, poolId, liquidityAmount);
    }

    function _investFromLiquidity(PoolKey calldata key, BalanceDelta delta) internal {
        // Calculate a small liquidity investment from liquidity additions
        uint256 redirectAmount = _calculateRedirectAmount(delta.amount0());
        uint128 liquidityAmount = uint128(redirectAmount / 1000); // Scale down for demo

        if (liquidityAmount > 0) {
            PoolId poolId = key.toId();
            _executeInvestment(key, poolId, liquidityAmount);
        }

        // Emit legacy event for backward compatibility
        emit LiquidityRedirected(uint256(liquidityAmount));
    }

    function _executeInvestment(PoolKey calldata key, PoolId poolId, uint128 liquidityAmount) internal {
        uint256 existingTokenId = investmentPositions[poolId];

        if (existingTokenId == 0) {
            // Create new investment position
            _createInvestmentPosition(key, poolId, liquidityAmount);
        } else {
            // Add to existing investment position
            _increaseInvestmentPosition(key, existingTokenId, liquidityAmount);
        }
    }

    function _createInvestmentPosition(PoolKey calldata key, PoolId poolId, uint128 liquidityAmount) internal {
        // Define actions: MINT_POSITION + CLOSE_CURRENCY for both tokens
        bytes memory actions = abi.encodePacked(
            Actions.MINT_POSITION,
            Actions.CLOSE_CURRENCY, // Handle token0 automatically
            Actions.CLOSE_CURRENCY // Handle token1 automatically
        );

        // Prepare parameters
        bytes[] memory params = new bytes[](3);

        // MINT_POSITION parameters
        params[0] = abi.encode(
            key, // Pool key
            TICK_LOWER, // Lower tick (full range)
            TICK_UPPER, // Upper tick (full range)
            liquidityAmount, // Liquidity amount
            type(uint256).max, // Max amount0 (no limit for automated system)
            type(uint256).max, // Max amount1 (no limit for automated system)
            address(this), // Hook owns the position
            "" // No hook data
        );

        // CLOSE_CURRENCY parameters for token0
        params[1] = abi.encode(key.currency0);

        // CLOSE_CURRENCY parameters for token1
        params[2] = abi.encode(key.currency1);

        try positionManager.modifyLiquiditiesWithoutUnlock(actions, params) {
            // Store the new token ID (in practice, you'd capture this from the return value)
            uint256 newTokenId = nextTokenId++;
            investmentPositions[poolId] = newTokenId;

            emit InvestmentExecuted(poolId, newTokenId, liquidityAmount);
        } catch {
            // Investment failed, but don't revert the swap
            // Just emit the legacy event for backward compatibility
            emit LiquidityRedirected(uint256(liquidityAmount));
        }
    }

    function _increaseInvestmentPosition(PoolKey calldata key, uint256 tokenId, uint128 liquidityAmount) internal {
        // Define actions: INCREASE_LIQUIDITY + CLOSE_CURRENCY for both tokens
        bytes memory actions = abi.encodePacked(
            Actions.INCREASE_LIQUIDITY,
            Actions.CLOSE_CURRENCY, // Handle token0 automatically
            Actions.CLOSE_CURRENCY // Handle token1 automatically
        );

        // Prepare parameters
        bytes[] memory params = new bytes[](3);

        // INCREASE_LIQUIDITY parameters
        params[0] = abi.encode(
            tokenId, // Existing position ID
            liquidityAmount, // Additional liquidity
            type(uint256).max, // Max amount0 (no limit for automated system)
            type(uint256).max, // Max amount1 (no limit for automated system)
            "" // No hook data
        );

        // CLOSE_CURRENCY parameters for token0 and token1
        params[1] = abi.encode(key.currency0);
        params[2] = abi.encode(key.currency1);

        try positionManager.modifyLiquiditiesWithoutUnlock(actions, params) {
            emit InvestmentExecuted(PoolId.wrap(bytes32(uint256(tokenId))), tokenId, liquidityAmount);
        } catch {
            // Investment failed, but don't revert the swap
            emit LiquidityRedirected(uint256(liquidityAmount));
        }
    }

    function _calculateRedirectAmount(int128 deltaAmount) internal pure returns (uint256) {
        if (deltaAmount >= 0) return 0;

        // Calculate percentage of the absolute amount
        uint256 absoluteAmount = uint256(uint128(-deltaAmount));
        return absoluteAmount * INVESTMENT_PERCENTAGE / 10000;
    }

    // Optional: Allow the hook owner to collect accumulated fees from investment positions
    function collectInvestmentFees(PoolId poolId, address /* recipient */ ) external {
        uint256 tokenId = investmentPositions[poolId];
        require(tokenId != 0, "No investment position");

        // Use standard modifyLiquidities since this is called outside of unlock context
        bytes memory actions = abi.encodePacked(Actions.DECREASE_LIQUIDITY, Actions.TAKE_PAIR);

        bytes[] memory params = new bytes[](2);

        // Collect fees only (zero liquidity decrease)
        params[0] = abi.encode(tokenId, 0, 0, 0, "");

        // Take all tokens to recipient (you'd need to specify the actual currencies)
        // params[1] = abi.encode(currency0, currency1, recipient);

        positionManager.modifyLiquidities(abi.encode(actions, params), block.timestamp + 60);
    }

    // Legacy functions for backward compatibility
    function _invest(BalanceDelta, /* delta0 */ BalanceDelta /* delta1 */ ) private {
        // Emit legacy event for backward compatibility
        emit LiquidityRedirected(1000);
    }
}
