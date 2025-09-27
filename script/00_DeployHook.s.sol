// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

import {BaseScript} from "./base/BaseScript.sol";

import {LiquidityRedirectHook} from "../src/LiquidityRedirectHook.sol";

// --- DEFINE TARGET POOL (poolAB) ---
// These should be the addresses for your target pool (e.g., WETH/WBTC)
IERC20 constant TARGET_TOKEN_0 = IERC20(
    address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
); // WETH
IERC20 constant TARGET_TOKEN_1 = IERC20(
    address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)
); // WBTC

/// @notice Mines the address and deploys the Counter.sol Hook contract
contract DeployHookScript is BaseScript {
    function run() public {
        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
            Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.AFTER_SWAP_FLAG
        );

        // Construct the target pool key
        (Currency targetCurrency0, Currency targetCurrency1) = getCurrencies(
            address(TARGET_TOKEN_0),
            address(TARGET_TOKEN_1)
        );
        PoolKey memory targetPoolKey = PoolKey({
            currency0: targetCurrency0,
            currency1: targetCurrency1,
            fee: 3000, // Fee for the target pool (e.g., 0.3%)
            tickSpacing: 60, // Tick spacing for the target pool
            hooks: IHooks(address(0)) // The target pool itself does not have a hook
        });

        // --- UPDATED CONSTRUCTOR ARGS ---
        bytes memory constructorArgs = abi.encode(
            poolManager,
            positionManager,
            targetPoolKey
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_FACTORY,
            flags,
            type(LiquidityRedirectHook).creationCode,
            constructorArgs
        );

        vm.startBroadcast();
        // --- UPDATED DEPLOYMENT CALL ---
        LiquidityRedirectHook hook = new LiquidityRedirectHook{salt: salt}(
            poolManager,
            positionManager,
            targetPoolKey
        );
        vm.stopBroadcast();

        require(
            address(hook) == hookAddress,
            "DeployHookScript: Hook Address Mismatch"
        );
    }

    // helper function to sort target tokens
    function getCurrencies(address token0, address token1) public pure returns (Currency, Currency) {
        require(token0 != token1, "Same token addresses");

        if (token0 < token1) {
            return (
                Currency.wrap(token0),
                Currency.wrap(token1)
            );
        } else {
            return (
                Currency.wrap(token1),
                Currency.wrap(token0)
            );
        }
    }
}
