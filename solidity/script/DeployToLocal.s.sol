// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InvestmentEngine} from "../src/InvestmentEngine.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";
import {IInvestmentEngine} from "../src/interfaces/IInvestmentEngine.sol";

/**
 * Enhanced local deployment script with comprehensive testing data
 * Simulates real-world usage scenarios for development and testing
 */
contract DeployToLocalScript is Script {
    PlanManager public planManager;
    InvestmentEngine public investmentEngine;

    // Mock token addresses for local testing
    address constant LOCAL_USDC = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1;
    address constant LOCAL_WETH = 0x4200000000000000000000000000000000000006;
    address constant LOCAL_WBTC = 0x68f180fcCe6836688e9084f035309E29Bf0A2095;
    address constant LOCAL_RWA_STOCK = 0x1234567890123456789012345678901234567890;
    address constant LOCAL_RWA_BOND = 0x0987654321098765432109876543210987654321;
    address constant LOCAL_LP_TOKEN = 0xabCDEF1234567890ABcDEF1234567890aBCDeF12;

    // Test user addresses (Anvil default accounts)
    address constant TEST_USER1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant TEST_USER2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address constant TEST_USER3 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

    function setUp() public {}

    function run() public {
        console.log("=== Deploying to Local Network (Anvil) ===");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);

        vm.startBroadcast();

        // Deploy contracts
        deployContracts();

        // Create comprehensive investment plans
        createComprehensivePlans();

        // Simulate realistic user scenarios
        simulateUserScenarios();

        // Display comprehensive summary
        displayLocalDeploymentSummary();

        vm.stopBroadcast();
    }

    function deployContracts() internal {
        console.log("\n=== Contract Deployment ===");

        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));

        investmentEngine = new InvestmentEngine();
        console.log("InvestmentEngine deployed at:", address(investmentEngine));

        investmentEngine.setPlanManager(address(planManager));
        console.log("Contracts linked successfully");

        // Set development-friendly minimum deposit
        investmentEngine.setMinimumDeposit(100); // Very low for testing
        console.log("Minimum deposit set to 100 wei for testing");
    }

    function createComprehensivePlans() internal {
        console.log("\n=== Creating Comprehensive Investment Plans ===");

        // 1. Ultra Conservative (90% Stablecoin, 10% RWA Bonds)
        createUltraConservativePlan();

        // 2. Conservative (60% Stablecoin, 40% RWA Mixed)
        createConservativePlan();

        // 3. Moderate (40% Stablecoin, 35% RWA, 25% Crypto)
        createModeratePlan();

        // 4. Balanced (30% Stablecoin, 30% RWA, 25% Crypto, 15% Liquidity)
        createBalancedPlan();

        // 5. Growth (20% Stablecoin, 25% RWA, 40% Crypto, 15% Liquidity)
        createGrowthPlan();

        // 6. Aggressive (10% Stablecoin, 20% RWA, 50% Crypto, 20% Liquidity)
        createAggressivePlan();

        // 7. DeFi Native (15% Stablecoin, 35% Liquidity, 50% Crypto)
        createDeFiNativePlan();
    }

    function createUltraConservativePlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](2);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: LOCAL_USDC,
            targetPercentage: 9000, // 90%
            minPercentage: 8500,
            maxPercentage: 9500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: LOCAL_RWA_BOND,
            targetPercentage: 1000, // 10%
            minPercentage: 500,
            maxPercentage: 1500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Ultra Conservative",
            allocations
        );

        console.log("Ultra Conservative Plan - ID:", planId, "Risk:", planManager.calculateRiskScore(allocations));
    }

    function createConservativePlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: LOCAL_USDC,
            targetPercentage: 6000, // 60%
            minPercentage: 5500,
            maxPercentage: 6500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: LOCAL_RWA_BOND,
            targetPercentage: 2500, // 25%
            minPercentage: 2000,
            maxPercentage: 3000
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: LOCAL_RWA_STOCK,
            targetPercentage: 1500, // 15%
            minPercentage: 1000,
            maxPercentage: 2000
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative Growth",
            allocations
        );

        console.log("Conservative Plan - ID:", planId, "Risk:", planManager.calculateRiskScore(allocations));
    }

    function createModeratePlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: LOCAL_USDC,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,
            maxPercentage: 4500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: LOCAL_RWA_STOCK,
            targetPercentage: 3500, // 35%
            minPercentage: 3000,
            maxPercentage: 4000
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: LOCAL_WETH,
            targetPercentage: 2500, // 25%
            minPercentage: 2000,
            maxPercentage: 3000
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Moderate Growth",
            allocations
        );

        console.log("Moderate Plan - ID:", planId, "Risk:", planManager.calculateRiskScore(allocations));
    }

    function createBalancedPlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](4);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: LOCAL_USDC,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: LOCAL_RWA_STOCK,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: LOCAL_WETH,
            targetPercentage: 2500, // 25%
            minPercentage: 2000,
            maxPercentage: 3000
        });

        allocations[3] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Liquidity,
            tokenAddress: LOCAL_LP_TOKEN,
            targetPercentage: 1500, // 15%
            minPercentage: 1000,
            maxPercentage: 2000
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Balanced Portfolio",
            allocations
        );

        console.log("Balanced Plan - ID:", planId, "Risk:", planManager.calculateRiskScore(allocations));
    }

    function createGrowthPlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](4);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: LOCAL_USDC,
            targetPercentage: 2000, // 20%
            minPercentage: 1500,
            maxPercentage: 2500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: LOCAL_RWA_STOCK,
            targetPercentage: 2500, // 25%
            minPercentage: 2000,
            maxPercentage: 3000
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: LOCAL_WETH,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,
            maxPercentage: 4500
        });

        allocations[3] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Liquidity,
            tokenAddress: LOCAL_LP_TOKEN,
            targetPercentage: 1500, // 15%
            minPercentage: 1000,
            maxPercentage: 2000
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "Growth Focused",
            allocations
        );

        console.log("Growth Plan - ID:", planId, "Risk:", planManager.calculateRiskScore(allocations));
    }

    function createAggressivePlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](4);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: LOCAL_USDC,
            targetPercentage: 1000, // 10%
            minPercentage: 500,
            maxPercentage: 1500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: LOCAL_RWA_STOCK,
            targetPercentage: 2000, // 20%
            minPercentage: 1500,
            maxPercentage: 2500
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: LOCAL_WETH,
            targetPercentage: 5000, // 50%
            minPercentage: 4500,
            maxPercentage: 5500
        });

        allocations[3] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Liquidity,
            tokenAddress: LOCAL_LP_TOKEN,
            targetPercentage: 2000, // 20%
            minPercentage: 1500,
            maxPercentage: 2500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "Aggressive Growth",
            allocations
        );

        console.log("Aggressive Plan - ID:", planId, "Risk:", planManager.calculateRiskScore(allocations));
    }

    function createDeFiNativePlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: LOCAL_USDC,
            targetPercentage: 1500, // 15%
            minPercentage: 1000,
            maxPercentage: 2000
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Liquidity,
            tokenAddress: LOCAL_LP_TOKEN,
            targetPercentage: 3500, // 35%
            minPercentage: 3000,
            maxPercentage: 4000
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: LOCAL_WBTC,
            targetPercentage: 5000, // 50%
            minPercentage: 4500,
            maxPercentage: 5500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Custom,
            "DeFi Native",
            allocations
        );

        console.log("DeFi Native Plan - ID:", planId, "Risk:", planManager.calculateRiskScore(allocations));
    }

    function simulateUserScenarios() internal {
        console.log("\n=== Simulating Realistic User Scenarios ===");

        // Scenario 1: Young Professional (Aggressive approach)
        simulateYoungProfessional();

        // Scenario 2: Mid-Career (Balanced approach)
        simulateMidCareer();

        // Scenario 3: Pre-Retirement (Conservative approach)
        simulatePreRetirement();

        console.log("\nUser scenarios simulation completed");
    }

    function simulateYoungProfessional() internal {
        console.log("\n--- Young Professional Scenario ---");

        // Multiple smaller deposits (salary + occasional bonuses)
        investmentEngine.depositForUser(TEST_USER1, 2000, IInvestmentEngine.DepositType.Salary);
        investmentEngine.depositForUser(TEST_USER1, 500, IInvestmentEngine.DepositType.EmployerMatch);
        investmentEngine.depositForUser(TEST_USER1, 1000, IInvestmentEngine.DepositType.Manual); // Bonus

        // Aggressive investment strategy
        uint256 investment1 = investmentEngine.invest(6, 2800); // Aggressive plan
        investmentEngine.executeInvestment(investment1);

        console.log("Young Professional setup complete");
        logUserBalance(TEST_USER1, "Young Professional");
    }

    function simulateMidCareer() internal {
        console.log("\n--- Mid-Career Professional Scenario ---");

        // Larger regular deposits
        investmentEngine.depositForUser(TEST_USER2, 5000, IInvestmentEngine.DepositType.Salary);
        investmentEngine.depositForUser(TEST_USER2, 2000, IInvestmentEngine.DepositType.EmployerMatch);
        investmentEngine.depositForUser(TEST_USER2, 3000, IInvestmentEngine.DepositType.Manual);

        // Balanced investment approach
        uint256 investment1 = investmentEngine.invest(4, 6000); // Balanced plan
        uint256 investment2 = investmentEngine.invest(5, 3000); // Growth plan
        investmentEngine.executeInvestment(investment1);
        // Leave investment2 pending to show mixed status

        console.log("Mid-Career Professional setup complete");
        logUserBalance(TEST_USER2, "Mid-Career Professional");
    }

    function simulatePreRetirement() internal {
        console.log("\n--- Pre-Retirement Scenario ---");

        // Large accumulated savings
        investmentEngine.depositForUser(TEST_USER3, 15000, IInvestmentEngine.DepositType.Manual);
        investmentEngine.depositForUser(TEST_USER3, 8000, IInvestmentEngine.DepositType.Salary);

        // Conservative investment approach
        uint256 investment1 = investmentEngine.invest(1, 12000); // Ultra Conservative
        uint256 investment2 = investmentEngine.invest(2, 8000);  // Conservative
        investmentEngine.executeInvestment(investment1);
        investmentEngine.executeInvestment(investment2);

        console.log("Pre-Retirement setup complete");
        logUserBalance(TEST_USER3, "Pre-Retirement");
    }

    function logUserBalance(address user, string memory userType) internal view {
        IInvestmentEngine.UserBalance memory balance = investmentEngine.getUserBalance(user);
        console.log(userType, "Balance:");
        console.log("  Total Deposited:", balance.totalDeposited);
        console.log("  Available:", balance.availableBalance);
        console.log("  Pending Investment:", balance.pendingInvestment);
        console.log("  Total Invested:", balance.totalInvested);
        console.log("  Portfolio Value:", investmentEngine.getUserPortfolioValue(user));
    }

    function displayLocalDeploymentSummary() internal view {
        console.log("\n=== Local Deployment Summary ===");
        console.log("Network: Local Anvil (Chain ID:", block.chainid, ")");
        console.log("PlanManager:", address(planManager));
        console.log("InvestmentEngine:", address(investmentEngine));
        console.log("Total Investment Plans:", planManager.getTotalPlans());

        console.log("\n=== Investment Plans Overview ===");
        IPlanManager.InvestmentPlan[] memory plans = planManager.getAllPlans();
        for (uint256 i = 0; i < plans.length; i++) {
            console.log("Plan ID:", i + 1);
            console.log("  Name:", plans[i].name);
            console.log("  Risk Score:", plans[i].riskScore);
        }

        console.log("\n=== User Portfolio Summary ===");
        console.log("Young Professional Portfolio:", investmentEngine.getUserPortfolioValue(TEST_USER1));
        console.log("Mid-Career Portfolio:", investmentEngine.getUserPortfolioValue(TEST_USER2));
        console.log("Pre-Retirement Portfolio:", investmentEngine.getUserPortfolioValue(TEST_USER3));

        console.log("\n=== Testing Commands ===");
        console.log("Run comprehensive tests:");
        console.log("forge script script/SimpleInvestmentTest.s.sol --rpc-url local --broadcast");
        console.log("forge script script/InteractiveInvestmentTest.s.sol --rpc-url local --broadcast");

        console.log("\n=== Contract Addresses for Frontend ===");
        console.log("PLAN_MANAGER_ADDRESS =", address(planManager));
        console.log("INVESTMENT_ENGINE_ADDRESS =", address(investmentEngine));
    }
}