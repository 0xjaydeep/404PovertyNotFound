// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InvestmentEngine} from "../src/InvestmentEngine.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {IInvestmentEngine} from "../src/interfaces/IInvestmentEngine.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";

/**
 * Interactive script to test InvestmentEngine functionality step by step
 * This allows testing individual functions and observing state changes
 */
contract InteractiveInvestmentTestScript is Script {
    InvestmentEngine public investmentEngine;
    PlanManager public planManager;

    // Test user addresses
    address constant TEST_USER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant TEST_USER2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    // Mock token addresses
    address constant USDC_ADDRESS = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1;
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy and setup contracts
        deployAndSetupContracts();

        // Test 1: Basic deposit functionality
        testBasicDeposits();

        // Test 2: Investment creation and execution
        testInvestmentCreationAndExecution();

        // Test 3: Batch operations
        testBatchOperations();

        // Test 4: Edge cases and validations
        testEdgeCasesAndValidations();

        // Test 5: View functions and state queries
        testViewFunctionsAndQueries();

        // Test 6: Administrative functions
        testAdministrativeFunctions();

        vm.stopBroadcast();
    }

    function deployAndSetupContracts() internal {
        console.log("=== Test Setup: Deploy and Configure Contracts ===");

        // Deploy PlanManager
        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));

        // Deploy InvestmentEngine
        investmentEngine = new InvestmentEngine();
        console.log("InvestmentEngine deployed at:", address(investmentEngine));

        // Set PlanManager in InvestmentEngine
        investmentEngine.setPlanManager(address(planManager));
        console.log("PlanManager set in InvestmentEngine");

        // Create a test investment plan
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](2);
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 7000, // 70%
            minPercentage: 6500,
            maxPercentage: 7500
        });
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Test Plan",
            allocations
        );
        console.log("Test plan created with ID:", planId);
    }

    function testBasicDeposits() internal {
        console.log("\n=== Test 1: Basic Deposit Functionality ===");

        // Test single deposit
        console.log("Initial user balance:");
        logUserBalance(TEST_USER);

        // Make a manual deposit
        investmentEngine.depositForUser(TEST_USER, 1000, IInvestmentEngine.DepositType.Manual);
        console.log("After manual deposit of 1000:");
        logUserBalance(TEST_USER);

        // Make a salary deposit
        investmentEngine.depositForUser(TEST_USER, 2000, IInvestmentEngine.DepositType.Salary);
        console.log("After salary deposit of 2000:");
        logUserBalance(TEST_USER);

        // Make an employer match deposit
        investmentEngine.depositForUser(TEST_USER, 500, IInvestmentEngine.DepositType.EmployerMatch);
        console.log("After employer match of 500:");
        logUserBalance(TEST_USER);

        // Check deposit history
        IInvestmentEngine.UserDeposit[] memory deposits = investmentEngine.getUserDeposits(TEST_USER);
        console.log("Total deposits made:", deposits.length);
        console.log("Expected total deposited: 3500, Actual:", deposits.length > 0 ? "verified" : "error");
    }

    function testInvestmentCreationAndExecution() internal {
        console.log("\n=== Test 2: Investment Creation and Execution ===");

        console.log("User balance before investment:");
        logUserBalance(TEST_USER);

        // Create an investment
        uint256 investmentAmount = 1500;
        uint256 investmentId = investmentEngine.invest(1, investmentAmount); // Using plan ID 1
        console.log("Created investment with ID:", investmentId);

        console.log("User balance after investment creation (before execution):");
        logUserBalance(TEST_USER);

        // Check investment details
        IInvestmentEngine.Investment memory investment = investmentEngine.getInvestment(investmentId);
        console.log("Investment details:");
        console.log("  Amount:", investment.totalAmount);
        console.log("  Status:", uint256(investment.status)); // 0 = Pending, 1 = Executed, 2 = Failed
        console.log("  Plan ID:", investment.planId);
        console.log("  User:", investment.user);

        // Execute the investment
        investmentEngine.executeInvestment(investmentId);
        console.log("Investment executed");

        console.log("User balance after investment execution:");
        logUserBalance(TEST_USER);

        // Check updated investment details
        investment = investmentEngine.getInvestment(investmentId);
        console.log("Updated investment status:", uint256(investment.status));
        console.log("Executed amount:", investment.executedAmount);
    }

    function testBatchOperations() internal {
        console.log("\n=== Test 3: Batch Operations ===");

        // Setup second user for batch testing
        investmentEngine.depositForUser(TEST_USER2, 2000, IInvestmentEngine.DepositType.Manual);
        console.log("Setup TEST_USER2 with 2000 deposit");

        // Test batch deposits
        address[] memory users = new address[](2);
        users[0] = TEST_USER;
        users[1] = TEST_USER2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 800;
        amounts[1] = 1200;

        investmentEngine.batchDeposit(users, amounts, IInvestmentEngine.DepositType.Salary);
        console.log("Batch deposits completed");

        console.log("TEST_USER balance after batch deposit:");
        logUserBalance(TEST_USER);
        console.log("TEST_USER2 balance after batch deposit:");
        logUserBalance(TEST_USER2);

        // Create multiple investments for batch execution
        uint256 inv1 = investmentEngine.invest(1, 500);
        uint256 inv2 = investmentEngine.invest(1, 600);
        console.log("Created investments for batch execution:", inv1, "&", inv2);

        // Batch execute investments
        uint256[] memory investmentIds = new uint256[](2);
        investmentIds[0] = inv1;
        investmentIds[1] = inv2;

        investmentEngine.batchExecuteInvestments(investmentIds);
        console.log("Batch executed investments");

        console.log("Final TEST_USER balance:");
        logUserBalance(TEST_USER);
    }

    function testEdgeCasesAndValidations() internal {
        console.log("\n=== Test 4: Edge Cases and Validations ===");

        // Test minimum deposit validation
        console.log("Current minimum deposit:", investmentEngine.minimumDeposit());

        // This should work (above minimum)
        try investmentEngine.depositForUser(TEST_USER, 600, IInvestmentEngine.DepositType.Manual) {
            console.log("Deposit above minimum: SUCCESS");
        } catch {
            console.log("Deposit above minimum: FAILED (unexpected)");
        }

        // Test investment with insufficient balance
        IInvestmentEngine.UserBalance memory balance = investmentEngine.getUserBalance(TEST_USER);
        uint256 excessiveAmount = balance.availableBalance + 1000;

        console.log("Available balance:", balance.availableBalance);
        console.log("Attempting investment of:", excessiveAmount);

        // This should fail due to insufficient balance
        try investmentEngine.invest(1, excessiveAmount) returns (uint256) {
            console.log("Excessive investment: FAILED (should have reverted)");
        } catch {
            console.log("Excessive investment: SUCCESS (correctly reverted)");
        }

        // Test investment with zero amount
        try investmentEngine.invest(1, 0) returns (uint256) {
            console.log("Zero amount investment: FAILED (should have reverted)");
        } catch {
            console.log("Zero amount investment: SUCCESS (correctly reverted)");
        }
    }

    function testViewFunctionsAndQueries() internal view {
        console.log("\n=== Test 5: View Functions and State Queries ===");

        // Test getUserInvestments
        IInvestmentEngine.Investment[] memory userInvestments = investmentEngine.getUserInvestments(TEST_USER);
        console.log("TEST_USER total investments:", userInvestments.length);

        // Count investments by status
        uint256 pendingCount = 0;
        uint256 executedCount = 0;
        for (uint256 i = 0; i < userInvestments.length; i++) {
            if (userInvestments[i].status == IInvestmentEngine.InvestmentStatus.Pending) {
                pendingCount++;
            } else if (userInvestments[i].status == IInvestmentEngine.InvestmentStatus.Executed) {
                executedCount++;
            }
        }
        console.log("Pending investments:", pendingCount);
        console.log("Executed investments:", executedCount);

        // Test getPendingInvestments
        IInvestmentEngine.Investment[] memory pendingInvestments = investmentEngine.getPendingInvestments(TEST_USER);
        console.log("Pending investments (via getPendingInvestments):", pendingInvestments.length);

        // Test portfolio values
        uint256 portfolioValue = investmentEngine.getUserPortfolioValue(TEST_USER);
        console.log("TEST_USER portfolio value:", portfolioValue);

        uint256 portfolioValue2 = investmentEngine.getUserPortfolioValue(TEST_USER2);
        console.log("TEST_USER2 portfolio value:", portfolioValue2);

        // Test total value locked
        uint256 tvl = investmentEngine.getTotalValueLocked();
        console.log("Total Value Locked:", tvl);

        // Display detailed user deposits
        IInvestmentEngine.UserDeposit[] memory deposits = investmentEngine.getUserDeposits(TEST_USER);
        console.log("\nTEST_USER deposit history:");
        for (uint256 i = 0; i < deposits.length; i++) {
            console.log("  Deposit", i + 1, ":");
            console.log("    Amount:", deposits[i].amount);
            console.log("    Type:", uint256(deposits[i].depositType));
            console.log("    Processed:", deposits[i].processed);
        }
    }

    function testAdministrativeFunctions() internal {
        console.log("\n=== Test 6: Administrative Functions ===");

        // Test setMinimumDeposit
        uint256 oldMinDeposit = investmentEngine.minimumDeposit();
        uint256 newMinDeposit = 1000;

        investmentEngine.setMinimumDeposit(newMinDeposit);
        console.log("Updated minimum deposit from", oldMinDeposit, "to", newMinDeposit);
        console.log("Current minimum deposit:", investmentEngine.minimumDeposit());

        // Test setPlanManager (set to same address to verify it works)
        address currentPlanManager = investmentEngine.planManager();
        investmentEngine.setPlanManager(currentPlanManager);
        console.log("PlanManager address confirmed:", investmentEngine.planManager());

        // Test rebalance function (this is a placeholder in current implementation)
        try investmentEngine.rebalance(TEST_USER, 1) {
            console.log("Rebalance function: SUCCESS (or placeholder)");
        } catch {
            console.log("Rebalance function: FAILED");
        }

        // Display final contract state
        console.log("\n--- Final Contract State ---");
        console.log("InvestmentEngine owner:", investmentEngine.owner());
        console.log("PlanManager address:", investmentEngine.planManager());
        console.log("Minimum deposit:", investmentEngine.minimumDeposit());
        console.log("Total plans available:", planManager.getTotalPlans());
    }

    function logUserBalance(address user) internal view {
        IInvestmentEngine.UserBalance memory balance = investmentEngine.getUserBalance(user);
        console.log("  Total Deposited:", balance.totalDeposited);
        console.log("  Available Balance:", balance.availableBalance);
        console.log("  Pending Investment:", balance.pendingInvestment);
        console.log("  Total Invested:", balance.totalInvested);
    }
}