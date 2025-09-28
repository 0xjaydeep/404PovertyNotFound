// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/PlanManager.sol";
import "../src/interfaces/IPlanManager.sol";

contract PlanCreationVerification is Script {
    PlanManager public planManager;

    // Mock crypto token addresses for testing
    address constant WBTC_ADDRESS = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant LINK_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant USDC_ADDRESS = 0xA0B86a33e6417e0f0e5B4fBC4fB74b95b2AB1c7f;

    function run() public {
        vm.startBroadcast();

        // Deploy PlanManager
        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));

        // Create test crypto plans
        console.log("\n=== Creating Crypto Investment Plans ===");

        // 1. Aggressive Crypto Plan
        uint256 aggressivePlanId = createAggressiveCryptoPlan();
        console.log("Aggressive Plan created with ID:", aggressivePlanId);

        // 2. Conservative Mixed Plan
        uint256 conservativePlanId = createConservativeMixedPlan();
        console.log("Conservative Plan created with ID:", conservativePlanId);

        // 3. Balanced Crypto Plan
        uint256 balancedPlanId = createBalancedCryptoPlan();
        console.log("Balanced Plan created with ID:", balancedPlanId);

        vm.stopBroadcast();

        console.log("\n=== Plan Creation Verification Complete ===");
        console.log("Total Plans Created:", planManager.getTotalPlans());
        console.log("PlanManager Address:", address(planManager));
        console.log("\nTo verify plans manually, use:");
        console.log("cast call", address(planManager), '"getPlan(uint256)" 1 --rpc-url http://127.0.0.1:8545');
        console.log("cast call", address(planManager), '"getTotalPlans()" --rpc-url http://127.0.0.1:8545');
    }

    function createAggressiveCryptoPlan() internal returns (uint256) {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        // 50% Bitcoin (WBTC)
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WBTC_ADDRESS,
            targetPercentage: 5000, // 50%
            minPercentage: 4000,    // 40%
            maxPercentage: 6000     // 60%
        });

        // 30% Ethereum (WETH)
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,    // 25%
            maxPercentage: 3500     // 35%
        });

        // 20% Chainlink (LINK)
        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: LINK_ADDRESS,
            targetPercentage: 2000, // 20%
            minPercentage: 1500,    // 15%
            maxPercentage: 2500     // 25%
        });

        return planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "Aggressive Crypto Portfolio",
            allocations
        );
    }

    function createConservativeMixedPlan() internal returns (uint256) {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        // 40% Ethereum (WETH)
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,    // 35%
            maxPercentage: 4500     // 45%
        });

        // 30% Bitcoin (WBTC)
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WBTC_ADDRESS,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,    // 25%
            maxPercentage: 3500     // 35%
        });

        // 30% Stablecoin (USDC)
        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,    // 25%
            maxPercentage: 3500     // 35%
        });

        return planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative Mixed Portfolio",
            allocations
        );
    }

    function createBalancedCryptoPlan() internal returns (uint256) {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](2);

        // 60% Ethereum (WETH)
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 6000, // 60%
            minPercentage: 5500,    // 55%
            maxPercentage: 6500     // 65%
        });

        // 40% Bitcoin (WBTC)
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WBTC_ADDRESS,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,    // 35%
            maxPercentage: 4500     // 45%
        });

        return planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Balanced Crypto Portfolio",
            allocations
        );
    }
}