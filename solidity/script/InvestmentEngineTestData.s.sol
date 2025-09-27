// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InvestmentEngine} from "../src/InvestmentEngine.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {IInvestmentEngine} from "../src/interfaces/IInvestmentEngine.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";

contract InvestmentEngineTestDataScript is Script {
    InvestmentEngine public investmentEngine;
    PlanManager public planManager;

    // Test users (using Anvil accounts)
    address constant USER1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Anvil account 1
    address constant USER2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Anvil account 2
    address constant USER3 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906; // Anvil account 3
    address constant EMPLOYER = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65; // Anvil account 4

    // Mock token addresses
    address constant USDC_ADDRESS = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1;
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant RWA_STOCK_ADDRESS = 0x1234567890123456789012345678901234567890;
    address constant RWA_BOND_ADDRESS = 0x0987654321098765432109876543210987654321;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy contracts
        deployContracts();

        // Create investment plans
        createInvestmentPlans();

        // Simulate user deposits and investments
        simulateUserDeposits();
        simulateUserInvestments();
        simulateBatchOperations();

        // Test view functions
        testViewFunctions();

        vm.stopBroadcast();
    }

    function deployContracts() internal {
        console.log("=== Deploying Contracts ===");

        // Deploy PlanManager first
        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));

        // Deploy InvestmentEngine
        investmentEngine = new InvestmentEngine();
        console.log("InvestmentEngine deployed at:", address(investmentEngine));

        // Set PlanManager in InvestmentEngine
        investmentEngine.setPlanManager(address(planManager));
        console.log("PlanManager set in InvestmentEngine");

        console.log("Owner:", investmentEngine.owner());
        console.log("Minimum Deposit:", investmentEngine.minimumDeposit());
    }

    function createInvestmentPlans() internal {
        console.log("\n=== Creating Investment Plans ===");

        // Create Conservative Plan (60% Stablecoin, 40% RWA)
        IPlanManager.AssetAllocation[] memory conservativeAlloc = new IPlanManager.AssetAllocation[](2);
        conservativeAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 6000,
            minPercentage: 5500,
            maxPercentage: 6500
        });
        conservativeAlloc[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: RWA_BOND_ADDRESS,
            targetPercentage: 4000,
            minPercentage: 3500,
            maxPercentage: 4500
        });

        uint256 conservativePlanId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative Plan",
            conservativeAlloc
        );
        console.log("Conservative Plan created with ID:", conservativePlanId);

        // Create Balanced Plan (30% Stablecoin, 40% RWA, 30% Crypto)
        IPlanManager.AssetAllocation[] memory balancedAlloc = new IPlanManager.AssetAllocation[](3);
        balancedAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 3000,
            minPercentage: 2500,
            maxPercentage: 3500
        });
        balancedAlloc[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: RWA_STOCK_ADDRESS,
            targetPercentage: 4000,
            minPercentage: 3500,
            maxPercentage: 4500
        });
        balancedAlloc[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 3000,
            minPercentage: 2500,
            maxPercentage: 3500
        });

        uint256 balancedPlanId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Balanced Plan",
            balancedAlloc
        );
        console.log("Balanced Plan created with ID:", balancedPlanId);
    }

    function simulateUserDeposits() internal {
        console.log("\n=== Simulating User Deposits ===");

        // User 1: Manual deposits
        investmentEngine.depositForUser(USER1, 1000, IInvestmentEngine.DepositType.Manual);
        investmentEngine.depositForUser(USER1, 2000, IInvestmentEngine.DepositType.Manual);
        console.log("User1 manual deposits: 1000 + 2000 = 3000 total");

        // User 2: Salary deposits
        investmentEngine.depositForUser(USER2, 5000, IInvestmentEngine.DepositType.Salary);
        investmentEngine.depositForUser(USER2, 1500, IInvestmentEngine.DepositType.EmployerMatch);
        console.log("User2 salary: 5000, employer match: 1500 = 6500 total");

        // User 3: Mixed deposits
        investmentEngine.depositForUser(USER3, 3000, IInvestmentEngine.DepositType.Manual);
        investmentEngine.depositForUser(USER3, 4000, IInvestmentEngine.DepositType.Salary);
        console.log("User3 manual: 3000, salary: 4000 = 7000 total");

        // Check balances after deposits
        console.log("\n--- User Balances After Deposits ---");
        logUserBalance(USER1, "USER1");
        logUserBalance(USER2, "USER2");
        logUserBalance(USER3, "USER3");
    }

    function simulateUserInvestments() internal {
        console.log("\n=== Simulating User Investments ===");

        // User 1: Conservative investment
        uint256 investment1 = investmentEngine.invest(1, 2500); // Conservative plan
        console.log("User1 investment ID:", investment1, "(Conservative plan, 2500)");

        // User 2: Balanced investment
        uint256 investment2 = investmentEngine.invest(2, 4000); // Balanced plan
        console.log("User2 investment ID:", investment2, "(Balanced plan, 4000)");

        // User 3: Multiple investments
        uint256 investment3a = investmentEngine.invest(1, 3000); // Conservative plan
        uint256 investment3b = investmentEngine.invest(2, 2000); // Balanced plan
        console.log("User3 investment IDs:", investment3a, "&", investment3b);

        // Check balances after investments (before execution)
        console.log("\n--- User Balances After Investment Creation ---");
        logUserBalance(USER1, "USER1");
        logUserBalance(USER2, "USER2");
        logUserBalance(USER3, "USER3");

        // Execute some investments
        console.log("\n--- Executing Investments ---");
        investmentEngine.executeInvestment(investment1);
        console.log("Executed investment", investment1);

        investmentEngine.executeInvestment(investment2);
        console.log("Executed investment", investment2);

        // Execute User3's investments together
        uint256[] memory user3Investments = new uint256[](2);
        user3Investments[0] = investment3a;
        user3Investments[1] = investment3b;
        investmentEngine.batchExecuteInvestments(user3Investments);
        console.log("Batch executed User3 investments");

        // Check final balances
        console.log("\n--- Final User Balances After Execution ---");
        logUserBalance(USER1, "USER1");
        logUserBalance(USER2, "USER2");
        logUserBalance(USER3, "USER3");
    }

    function simulateBatchOperations() internal {
        console.log("\n=== Simulating Batch Operations ===");

        // Batch deposits for multiple users
        address[] memory users = new address[](3);
        users[0] = USER1;
        users[1] = USER2;
        users[2] = USER3;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1000;
        amounts[1] = 1500;
        amounts[2] = 2000;

        investmentEngine.batchDeposit(users, amounts, IInvestmentEngine.DepositType.Salary);
        console.log("Batch salary deposits completed");

        // Create investments for batch execution
        uint256 batchInv1 = investmentEngine.invest(1, 500);
        uint256 batchInv2 = investmentEngine.invest(2, 750);
        uint256 batchInv3 = investmentEngine.invest(1, 1000);

        uint256[] memory batchInvestments = new uint256[](3);
        batchInvestments[0] = batchInv1;
        batchInvestments[1] = batchInv2;
        batchInvestments[2] = batchInv3;

        investmentEngine.batchExecuteInvestments(batchInvestments);
        console.log("Batch investments executed");
    }

    function testViewFunctions() internal view {
        console.log("\n=== Testing View Functions ===");

        // Test getUserDeposits
        IInvestmentEngine.UserDeposit[] memory user1Deposits = investmentEngine.getUserDeposits(USER1);
        console.log("User1 deposit count:", user1Deposits.length);

        // Test getUserInvestments
        IInvestmentEngine.Investment[] memory user2Investments = investmentEngine.getUserInvestments(USER2);
        console.log("User2 investment count:", user2Investments.length);

        // Test getPendingInvestments
        IInvestmentEngine.Investment[] memory user3Pending = investmentEngine.getPendingInvestments(USER3);
        console.log("User3 pending investments:", user3Pending.length);

        // Test portfolio values
        console.log("\n--- Portfolio Values ---");
        console.log("User1 portfolio value:", investmentEngine.getUserPortfolioValue(USER1));
        console.log("User2 portfolio value:", investmentEngine.getUserPortfolioValue(USER2));
        console.log("User3 portfolio value:", investmentEngine.getUserPortfolioValue(USER3));

        // Test total value locked
        console.log("Total Value Locked:", investmentEngine.getTotalValueLocked());

        // Show detailed investment information
        console.log("\n--- Investment Details ---");
        for (uint256 i = 1; i <= 8; i++) {
            try investmentEngine.getInvestment(i) returns (IInvestmentEngine.Investment memory inv) {
                console.log("Investment", i, ":");
                console.log("  User:", inv.user);
                console.log("  Plan ID:", inv.planId);
                console.log("  Amount:", inv.totalAmount);
                console.log("  Status:", uint256(inv.status));
                console.log("  Executed Amount:", inv.executedAmount);
            } catch {
                // Investment doesn't exist
            }
        }
    }

    function logUserBalance(address user, string memory userName) internal view {
        IInvestmentEngine.UserBalance memory balance = investmentEngine.getUserBalance(user);
        console.log(userName, "balance:");
        console.log("  Total Deposited:", balance.totalDeposited);
        console.log("  Available:", balance.availableBalance);
        console.log("  Pending Investment:", balance.pendingInvestment);
        console.log("  Total Invested:", balance.totalInvested);
    }
}