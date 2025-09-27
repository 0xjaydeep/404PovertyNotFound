// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/PlanManager.sol";
import "../src/InvestmentEngine.sol";
import "../src/interfaces/IPlanManager.sol";
import "../src/interfaces/IInvestmentEngine.sol";

contract CryptoOnlyInvestmentTest is Script {
    PlanManager public planManager;
    InvestmentEngine public investmentEngine;

    // Mock crypto token addresses (for testing purposes)
    address constant WBTC_ADDRESS = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant LINK_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant UNI_ADDRESS = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant USDC_ADDRESS = 0xA0B86a33e6417e0f0e5B4fBC4fB74b95b2AB1c7f;

    // Test users
    address testUser1 = makeAddr("testUser1");
    address testUser2 = makeAddr("testUser2");

    function setUp() public {
        // Deploy contracts
        planManager = new PlanManager();
        investmentEngine = new InvestmentEngine();

        // Set plan manager in investment engine
        investmentEngine.setPlanManager(address(planManager));

        console.log("=== Crypto-Only Investment Test Setup ===");
        console.log("PlanManager deployed at:", address(planManager));
        console.log("InvestmentEngine deployed at:", address(investmentEngine));
        console.log("Test User 1:", testUser1);
        console.log("Test User 2:", testUser2);
    }

    function run() public {
        vm.startBroadcast();

        // Deploy contracts for this test
        planManager = new PlanManager();
        investmentEngine = new InvestmentEngine();
        investmentEngine.setPlanManager(address(planManager));

        console.log("=== Crypto-Only Investment Test Setup ===");
        console.log("PlanManager deployed at:", address(planManager));
        console.log("InvestmentEngine deployed at:", address(investmentEngine));
        console.log("Test User 1:", testUser1);
        console.log("Test User 2:", testUser2);

        // Test 1: Create Aggressive Crypto Portfolio (100% Crypto)
        console.log("\n=== Test 1: Creating Aggressive Crypto Portfolio ===");
        uint256 aggressivePlanId = createAggressiveCryptoPlan();

        // Test 2: Create Conservative Crypto Portfolio (Mixed crypto with stablecoins)
        console.log("\n=== Test 2: Creating Conservative Crypto Portfolio ===");
        uint256 conservativePlanId = createConservativeCryptoPlan();

        // Test 3: Create Custom Multi-Crypto Portfolio
        console.log("\n=== Test 3: Creating Custom Multi-Crypto Portfolio ===");
        uint256 customPlanId = createCustomCryptoPlan();

        // Test 4: Simulate user investments
        console.log("\n=== Test 4: Simulating User Investments ===");
        testUserInvestmentsSimple(aggressivePlanId, conservativePlanId, customPlanId);

        // Test 5: Display portfolio analytics
        console.log("\n=== Test 5: Portfolio Analytics ===");
        displayPortfolioAnalytics();

        vm.stopBroadcast();
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

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "Aggressive Crypto Portfolio",
            allocations
        );

        IPlanManager.InvestmentPlan memory plan = planManager.getPlan(planId);

        console.log("Created Aggressive Crypto Plan:");
        console.log("  Plan ID:", planId);
        console.log("  Name:", plan.name);
        console.log("  Risk Score:", plan.riskScore);
        console.log("  Allocations:");
        console.log("    - WBTC: 50%");
        console.log("    - WETH: 30%");
        console.log("    - LINK: 20%");

        return planId;
    }

    function createConservativeCryptoPlan() internal returns (uint256) {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        // 40% Ethereum (WETH) - More stable crypto
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,    // 35%
            maxPercentage: 4500     // 45%
        });

        // 30% Bitcoin (WBTC) - Store of value
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
            tokenAddress: USDC_ADDRESS, // Mock USDC
            targetPercentage: 3000, // 30%
            minPercentage: 2500,    // 25%
            maxPercentage: 3500     // 35%
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative Crypto Portfolio",
            allocations
        );

        IPlanManager.InvestmentPlan memory plan = planManager.getPlan(planId);

        console.log("Created Conservative Crypto Plan:");
        console.log("  Plan ID:", planId);
        console.log("  Name:", plan.name);
        console.log("  Risk Score:", plan.riskScore);
        console.log("  Allocations:");
        console.log("    - WETH: 40%");
        console.log("    - WBTC: 30%");
        console.log("    - USDC: 30%");

        return planId;
    }

    function createCustomCryptoPlan() internal returns (uint256) {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](4);

        // 25% Bitcoin (WBTC)
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WBTC_ADDRESS,
            targetPercentage: 2500, // 25%
            minPercentage: 2000,    // 20%
            maxPercentage: 3000     // 30%
        });

        // 25% Ethereum (WETH)
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 2500, // 25%
            minPercentage: 2000,    // 20%
            maxPercentage: 3000     // 30%
        });

        // 25% Chainlink (LINK)
        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: LINK_ADDRESS,
            targetPercentage: 2500, // 25%
            minPercentage: 2000,    // 20%
            maxPercentage: 3000     // 30%
        });

        // 25% Uniswap (UNI)
        allocations[3] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: UNI_ADDRESS,
            targetPercentage: 2500, // 25%
            minPercentage: 2000,    // 20%
            maxPercentage: 3000     // 30%
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Custom,
            "Diversified Crypto Portfolio",
            allocations
        );

        IPlanManager.InvestmentPlan memory plan = planManager.getPlan(planId);

        console.log("Created Custom Crypto Plan:");
        console.log("  Plan ID:", planId);
        console.log("  Name:", plan.name);
        console.log("  Risk Score:", plan.riskScore);
        console.log("  Allocations:");
        console.log("    - WBTC: 25%");
        console.log("    - WETH: 25%");
        console.log("    - LINK: 25%");
        console.log("    - UNI: 25%");

        return planId;
    }

    function testUserInvestmentsSimple(
        uint256 aggressivePlanId,
        uint256 conservativePlanId,
        uint256 customPlanId
    ) internal {
        // Simulate deposits for test users
        uint256 depositAmount1 = 10000; // 10,000 units
        uint256 depositAmount2 = 5000;  // 5,000 units

        console.log("Processing deposits for test users...");

        // User 1 deposits
        investmentEngine.depositForUser(
            testUser1,
            depositAmount1,
            IInvestmentEngine.DepositType.Salary
        );

        // User 2 deposits
        investmentEngine.depositForUser(
            testUser2,
            depositAmount2,
            IInvestmentEngine.DepositType.Manual
        );

        console.log("User deposits completed:");
        console.log("  User 1 deposited:", depositAmount1);
        console.log("  User 2 deposited:", depositAmount2);

        // Test actual investment functionality
        console.log("\nTesting investment functionality...");

        // Verify plan IDs are correct
        console.log("Plan IDs created:");
        console.log("  Aggressive Plan ID:", aggressivePlanId);
        console.log("  Conservative Plan ID:", conservativePlanId);
        console.log("  Custom Plan ID:", customPlanId);

        // Verify plans exist and can be retrieved
        console.log("\nVerifying plan creation...");
        IPlanManager.InvestmentPlan memory plan1 = planManager.getPlan(aggressivePlanId);
        IPlanManager.InvestmentPlan memory plan2 = planManager.getPlan(conservativePlanId);
        IPlanManager.InvestmentPlan memory plan3 = planManager.getPlan(customPlanId);

        console.log("Plan 1 verification - ID:", plan1.planId, "Name:", plan1.name);
        console.log("Plan 2 verification - ID:", plan2.planId, "Name:", plan2.name);
        console.log("Plan 3 verification - ID:", plan3.planId, "Name:", plan3.name);

        // Create test investments using owner account (demonstrates plan validation)
        console.log("\nCreating test investments using owner account...");
        console.log("Note: In production, users would call invest() with their own accounts");

        // Deposit for the owner account to test investment creation
        investmentEngine.depositForUser(
            address(this),
            20000,
            IInvestmentEngine.DepositType.Manual
        );
        console.log("Owner account funded with 20000 units for testing");

        // Investment 1: Owner → Aggressive Plan (8000 units)
        uint256 investment1 = investmentEngine.invest(aggressivePlanId, 8000);
        console.log("Investment 1 created with ID:", investment1, "for Aggressive Plan ID:", aggressivePlanId);

        // Investment 2: Owner → Conservative Plan (2000 units)
        uint256 investment2 = investmentEngine.invest(conservativePlanId, 2000);
        console.log("Investment 2 created with ID:", investment2, "for Conservative Plan ID:", conservativePlanId);

        // Investment 3: Owner → Custom Plan (4000 units)
        uint256 investment3 = investmentEngine.invest(customPlanId, 4000);
        console.log("Investment 3 created with ID:", investment3, "for Custom Plan ID:", customPlanId);

        // Execute the investments
        console.log("\nExecuting investments...");
        investmentEngine.executeInvestment(investment1);
        investmentEngine.executeInvestment(investment2);
        investmentEngine.executeInvestment(investment3);
        console.log("Investments executed successfully!");

        // Verify final balances
        console.log("\nFinal balance verification:");

        // User 1 balances (from initial deposits)
        IInvestmentEngine.UserBalance memory balance1 = investmentEngine.getUserBalance(testUser1);
        console.log("User 1 Balance (deposit-only):");
        console.log("  Available Balance:", balance1.availableBalance);
        console.log("  Total Invested:", balance1.totalInvested);
        console.log("  Pending Investment:", balance1.pendingInvestment);

        // User 2 balances (from initial deposits)
        IInvestmentEngine.UserBalance memory balance2 = investmentEngine.getUserBalance(testUser2);
        console.log("User 2 Balance (deposit-only):");
        console.log("  Available Balance:", balance2.availableBalance);
        console.log("  Total Invested:", balance2.totalInvested);
        console.log("  Pending Investment:", balance2.pendingInvestment);

        // Owner balances (with investments)
        IInvestmentEngine.UserBalance memory ownerBalance = investmentEngine.getUserBalance(address(this));
        console.log("Owner Balance (with investments):");
        console.log("  Available Balance:", ownerBalance.availableBalance);
        console.log("  Total Invested:", ownerBalance.totalInvested);
        console.log("  Pending Investment:", ownerBalance.pendingInvestment);
    }

    function displayPortfolioAnalytics() internal view {
        console.log("=== Portfolio Analytics ===");

        // Display user balances
        IInvestmentEngine.UserBalance memory balance1 = investmentEngine.getUserBalance(testUser1);
        IInvestmentEngine.UserBalance memory balance2 = investmentEngine.getUserBalance(testUser2);

        console.log("\nUser 1 Portfolio:");
        console.log("  Total Deposited:", balance1.totalDeposited);
        console.log("  Total Invested:", balance1.totalInvested);
        console.log("  Available Balance:", balance1.availableBalance);
        console.log("  Pending Investment:", balance1.pendingInvestment);
        console.log("  Portfolio Value:", investmentEngine.getUserPortfolioValue(testUser1));

        console.log("\nUser 2 Portfolio:");
        console.log("  Total Deposited:", balance2.totalDeposited);
        console.log("  Total Invested:", balance2.totalInvested);
        console.log("  Available Balance:", balance2.availableBalance);
        console.log("  Pending Investment:", balance2.pendingInvestment);
        console.log("  Portfolio Value:", investmentEngine.getUserPortfolioValue(testUser2));

        // Display all plans
        console.log("\nAll Investment Plans:");
        IPlanManager.InvestmentPlan[] memory allPlans = planManager.getAllPlans();
        for (uint256 i = 0; i < allPlans.length; i++) {
            console.log("  Plan", allPlans[i].planId, ":", allPlans[i].name);
            console.log("    Risk Score:", allPlans[i].riskScore);
            console.log("    Active:", allPlans[i].isActive);
        }

        // Display total plans count
        console.log("\nTotal Plans Created:", planManager.getTotalPlans());
    }

    // Helper function to validate crypto-only allocation
    function validateCryptoOnlyAllocation(IPlanManager.AssetAllocation[] memory allocations)
        internal
        pure
        returns (bool isCryptoOnly)
    {
        isCryptoOnly = true;
        for (uint256 i = 0; i < allocations.length; i++) {
            if (allocations[i].assetClass != IPlanManager.AssetClass.Crypto) {
                isCryptoOnly = false;
                break;
            }
        }
        return isCryptoOnly;
    }

    // Test function to demonstrate crypto-only validation
    function testCryptoOnlyValidation() public view {
        console.log("\n=== Crypto-Only Validation Test ===");

        // Test pure crypto allocation
        IPlanManager.AssetAllocation[] memory cryptoAlloc = new IPlanManager.AssetAllocation[](2);
        cryptoAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WBTC_ADDRESS,
            targetPercentage: 6000,
            minPercentage: 5000,
            maxPercentage: 7000
        });
        cryptoAlloc[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 4000,
            minPercentage: 3000,
            maxPercentage: 5000
        });

        bool isCryptoOnly = validateCryptoOnlyAllocation(cryptoAlloc);
        console.log("Pure crypto allocation is crypto-only:", isCryptoOnly);

        // Test mixed allocation
        IPlanManager.AssetAllocation[] memory mixedAlloc = new IPlanManager.AssetAllocation[](2);
        mixedAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WBTC_ADDRESS,
            targetPercentage: 7000,
            minPercentage: 6000,
            maxPercentage: 8000
        });
        mixedAlloc[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 3000,
            minPercentage: 2000,
            maxPercentage: 4000
        });

        bool isMixedCryptoOnly = validateCryptoOnlyAllocation(mixedAlloc);
        console.log("Mixed allocation is crypto-only:", isMixedCryptoOnly);
    }
}