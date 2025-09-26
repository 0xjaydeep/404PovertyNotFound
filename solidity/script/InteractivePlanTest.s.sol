// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";

/**
 * Interactive script to test PlanManager functionality step by step
 * This allows testing individual functions and observing state changes
 */
contract InteractivePlanTestScript is Script {
    PlanManager public planManager;

    // Mock token addresses for testing
    address constant USDC_ADDRESS = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1;
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant RWA_STOCK_ADDRESS = 0x1234567890123456789012345678901234567890;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy PlanManager
        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));

        // Test 1: Create a simple plan
        testCreateSimplePlan();

        // Test 2: Test validation edge cases
        testValidationEdgeCases();

        // Test 3: Test plan updates
        testPlanUpdates();

        // Test 4: Test view functions
        testViewFunctions();

        // Test 5: Test risk score calculations
        testRiskCalculations();

        vm.stopBroadcast();
    }

    function testCreateSimplePlan() internal {
        console.log("\n=== Test 1: Create Simple Plan ===");

        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](2);

        // 70% Stablecoin
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 7000,
            minPercentage: 6500,
            maxPercentage: 7500
        });

        // 30% RWA
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: RWA_STOCK_ADDRESS,
            targetPercentage: 3000,
            minPercentage: 2500,
            maxPercentage: 3500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Simple Test Plan",
            allocations
        );

        console.log("Created plan with ID:", planId);
        console.log("Total plans:", planManager.getTotalPlans());

        // Get and display plan
        IPlanManager.InvestmentPlan memory plan = planManager.getPlan(planId);
        console.log("Plan name:", plan.name);
        console.log("Plan risk score:", plan.riskScore);
        console.log("Plan is active:", plan.isActive);
    }

    function testValidationEdgeCases() internal {
        console.log("\n=== Test 2: Validation Edge Cases ===");

        // Test case: Exactly 100% allocation
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](1);
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 10000, // Exactly 100%
            minPercentage: 9500,
            maxPercentage: 10000
        });

        bool isValid = planManager.validateAllocation(allocations);
        console.log("100% single asset allocation valid:", isValid);

        // Calculate risk score for 100% stablecoin
        uint256 riskScore = planManager.calculateRiskScore(allocations);
        console.log("Risk score for 100% stablecoin:", riskScore);
    }

    function testPlanUpdates() internal {
        console.log("\n=== Test 3: Plan Updates ===");

        // Create a plan to update
        IPlanManager.AssetAllocation[] memory initialAllocations = new IPlanManager.AssetAllocation[](2);
        initialAllocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 5000,
            minPercentage: 4500,
            maxPercentage: 5500
        });
        initialAllocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 5000,
            minPercentage: 4500,
            maxPercentage: 5500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Update Test Plan",
            initialAllocations
        );

        IPlanManager.InvestmentPlan memory planBefore = planManager.getPlan(planId);
        console.log("Risk score before update:", planBefore.riskScore);
        console.log("Updated at before:", planBefore.updatedAt);

        // Wait a bit and update
        vm.warp(block.timestamp + 1);

        // Update to more aggressive allocation
        IPlanManager.AssetAllocation[] memory newAllocations = new IPlanManager.AssetAllocation[](2);
        newAllocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 2000, // Reduced to 20%
            minPercentage: 1500,
            maxPercentage: 2500
        });
        newAllocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 8000, // Increased to 80%
            minPercentage: 7500,
            maxPercentage: 8500
        });

        planManager.updatePlan(planId, newAllocations);

        IPlanManager.InvestmentPlan memory planAfter = planManager.getPlan(planId);
        console.log("Risk score after update:", planAfter.riskScore);
        console.log("Updated at after:", planAfter.updatedAt);
        console.log("Update successful:", planAfter.updatedAt > planBefore.updatedAt);
    }

    function testViewFunctions() internal view {
        console.log("\n=== Test 4: View Functions ===");

        uint256 totalPlans = planManager.getTotalPlans();
        console.log("Total plans created:", totalPlans);

        IPlanManager.InvestmentPlan[] memory allPlans = planManager.getAllPlans();
        console.log("All plans array length:", allPlans.length);

        IPlanManager.InvestmentPlan[] memory activePlans = planManager.getActivePlans();
        console.log("Active plans count:", activePlans.length);

        // Test asset allocation limits for first plan
        if (totalPlans > 0) {
            IPlanManager.AssetAllocation[] memory allocations = planManager.getAssetAllocationLimits(1);
            console.log("Plan 1 allocation count:", allocations.length);
            if (allocations.length > 0) {
                console.log("First allocation target %:", allocations[0].targetPercentage);
            }
        }
    }

    function testRiskCalculations() internal view {
        console.log("\n=== Test 5: Risk Score Calculations ===");

        // Test different risk profiles
        IPlanManager.AssetAllocation[] memory conservativeAlloc = new IPlanManager.AssetAllocation[](1);
        conservativeAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 10000,
            minPercentage: 9500,
            maxPercentage: 10000
        });

        IPlanManager.AssetAllocation[] memory aggressiveAlloc = new IPlanManager.AssetAllocation[](1);
        aggressiveAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 10000,
            minPercentage: 9500,
            maxPercentage: 10000
        });

        IPlanManager.AssetAllocation[] memory mixedAlloc = new IPlanManager.AssetAllocation[](4);
        mixedAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 2500,
            minPercentage: 2000,
            maxPercentage: 3000
        });
        mixedAlloc[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: RWA_STOCK_ADDRESS,
            targetPercentage: 2500,
            minPercentage: 2000,
            maxPercentage: 3000
        });
        mixedAlloc[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Liquidity,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 2500,
            minPercentage: 2000,
            maxPercentage: 3000
        });
        mixedAlloc[3] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 2500,
            minPercentage: 2000,
            maxPercentage: 3000
        });

        uint256 conservativeRisk = planManager.calculateRiskScore(conservativeAlloc);
        uint256 aggressiveRisk = planManager.calculateRiskScore(aggressiveAlloc);
        uint256 mixedRisk = planManager.calculateRiskScore(mixedAlloc);

        console.log("100% Stablecoin risk score:", conservativeRisk);
        console.log("100% Crypto risk score:", aggressiveRisk);
        console.log("25% each asset class risk score:", mixedRisk);

        // Display asset risk factors
        console.log("\nAsset Risk Factors:");
        console.log("Stablecoin:", planManager.assetRiskFactors(IPlanManager.AssetClass.Stablecoin));
        console.log("RWA:", planManager.assetRiskFactors(IPlanManager.AssetClass.RWA));
        console.log("Liquidity:", planManager.assetRiskFactors(IPlanManager.AssetClass.Liquidity));
        console.log("Crypto:", planManager.assetRiskFactors(IPlanManager.AssetClass.Crypto));
    }
}