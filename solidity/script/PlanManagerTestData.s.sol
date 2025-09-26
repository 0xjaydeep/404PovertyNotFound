// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";

contract PlanManagerTestDataScript is Script {
    PlanManager public planManager;

    // Mock token addresses for testing
    address constant USDC_ADDRESS = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1; // Mock USDC
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006; // Mock WETH
    address constant WBTC_ADDRESS = 0x68f180fcCe6836688e9084f035309E29Bf0A2095; // Mock WBTC
    address constant RWA_STOCK_ADDRESS = 0x1234567890123456789012345678901234567890; // Mock RWA Stock Token
    address constant RWA_BOND_ADDRESS = 0x0987654321098765432109876543210987654321; // Mock RWA Bond Token
    address constant LP_TOKEN_ADDRESS = 0xabCDEF1234567890ABcDEF1234567890aBCDeF12; // Mock LP Token

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy PlanManager
        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));

        // Create test data
        createConservativePlan();
        createBalancedPlan();
        createAggressivePlan();
        createCustomPlan();

        // Test view functions
        testViewFunctions();

        vm.stopBroadcast();
    }

    function createConservativePlan() internal {
        console.log("\n=== Creating Conservative Plan ===");

        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        // 60% Stablecoin (USDC)
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 6000, // 60%
            minPercentage: 5500,    // 55%
            maxPercentage: 6500     // 65%
        });

        // 30% RWA Bonds
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: RWA_BOND_ADDRESS,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,    // 25%
            maxPercentage: 3500     // 35%
        });

        // 10% Crypto (ETH)
        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 1000, // 10%
            minPercentage: 500,     // 5%
            maxPercentage: 1500     // 15%
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative Growth Plan",
            allocations
        );

        console.log("Conservative Plan created with ID:", planId);

        // Get and display plan details
        IPlanManager.InvestmentPlan memory plan = planManager.getPlan(planId);
        console.log("Risk Score:", plan.riskScore);
    }

    function createBalancedPlan() internal {
        console.log("\n=== Creating Balanced Plan ===");

        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](4);

        // 30% Stablecoin (USDC)
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,    // 25%
            maxPercentage: 3500     // 35%
        });

        // 35% RWA Stocks
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: RWA_STOCK_ADDRESS,
            targetPercentage: 3500, // 35%
            minPercentage: 3000,    // 30%
            maxPercentage: 4000     // 40%
        });

        // 20% Crypto (ETH)
        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 2000, // 20%
            minPercentage: 1500,    // 15%
            maxPercentage: 2500     // 25%
        });

        // 15% Liquidity Provision
        allocations[3] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Liquidity,
            tokenAddress: LP_TOKEN_ADDRESS,
            targetPercentage: 1500, // 15%
            minPercentage: 1000,    // 10%
            maxPercentage: 2000     // 20%
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Balanced Portfolio Plan",
            allocations
        );

        console.log("Balanced Plan created with ID:", planId);

        // Get and display plan details
        IPlanManager.InvestmentPlan memory plan = planManager.getPlan(planId);
        console.log("Risk Score:", plan.riskScore);
    }

    function createAggressivePlan() internal {
        console.log("\n=== Creating Aggressive Plan ===");

        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](4);

        // 10% Stablecoin (USDC)
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 1000, // 10%
            minPercentage: 500,     // 5%
            maxPercentage: 1500     // 15%
        });

        // 20% RWA Stocks
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: RWA_STOCK_ADDRESS,
            targetPercentage: 2000, // 20%
            minPercentage: 1500,    // 15%
            maxPercentage: 2500     // 25%
        });

        // 30% Crypto (ETH)
        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,    // 25%
            maxPercentage: 3500     // 35%
        });

        // 40% Crypto (BTC) + Liquidity
        allocations[3] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WBTC_ADDRESS,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,    // 35%
            maxPercentage: 4500     // 45%
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "Aggressive Growth Plan",
            allocations
        );

        console.log("Aggressive Plan created with ID:", planId);

        // Get and display plan details
        IPlanManager.InvestmentPlan memory plan = planManager.getPlan(planId);
        console.log("Risk Score:", plan.riskScore);
    }

    function createCustomPlan() internal {
        console.log("\n=== Creating Custom Plan ===");

        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        // 40% RWA Stocks
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: RWA_STOCK_ADDRESS,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,    // 35%
            maxPercentage: 4500     // 45%
        });

        // 30% RWA Bonds
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: RWA_BOND_ADDRESS,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,    // 25%
            maxPercentage: 3500     // 35%
        });

        // 30% Liquidity Provision
        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Liquidity,
            tokenAddress: LP_TOKEN_ADDRESS,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,    // 25%
            maxPercentage: 3500     // 35%
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Custom,
            "Custom RWA-Focus Plan",
            allocations
        );

        console.log("Custom Plan created with ID:", planId);

        // Get and display plan details
        IPlanManager.InvestmentPlan memory plan = planManager.getPlan(planId);
        console.log("Risk Score:", plan.riskScore);
    }

    function testViewFunctions() internal view {
        console.log("\n=== Testing View Functions ===");

        uint256 totalPlans = planManager.getTotalPlans();
        console.log("Total Plans:", totalPlans);

        console.log("\n--- All Plans ---");
        IPlanManager.InvestmentPlan[] memory allPlans = planManager.getAllPlans();
        for (uint256 i = 0; i < allPlans.length; i++) {
            console.log("Plan", i + 1, ":", allPlans[i].name);
            console.log("  Type:", uint256(allPlans[i].planType));
            console.log("  Risk Score:", allPlans[i].riskScore);
            console.log("  Active:", allPlans[i].isActive);
            console.log("  Allocations Count:", allPlans[i].allocations.length);
        }

        console.log("\n--- Active Plans ---");
        IPlanManager.InvestmentPlan[] memory activePlans = planManager.getActivePlans();
        console.log("Active Plans Count:", activePlans.length);

        // Test asset allocation limits for first plan
        if (totalPlans > 0) {
            console.log("\n--- Asset Allocation for Plan 1 ---");
            IPlanManager.AssetAllocation[] memory allocations = planManager.getAssetAllocationLimits(1);
            for (uint256 i = 0; i < allocations.length; i++) {
                console.log("Asset Class:", uint256(allocations[i].assetClass));
                console.log("  Token:", allocations[i].tokenAddress);
                console.log("  Target %:", allocations[i].targetPercentage);
                console.log("  Min %:", allocations[i].minPercentage);
                console.log("  Max %:", allocations[i].maxPercentage);
            }
        }
    }
}