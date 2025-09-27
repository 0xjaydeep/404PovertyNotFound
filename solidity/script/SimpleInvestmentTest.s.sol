// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InvestmentEngine} from "../src/InvestmentEngine.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {IInvestmentEngine} from "../src/interfaces/IInvestmentEngine.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";

/**
 * Simple test script that works with current InvestmentEngine limitations
 * Uses script address as the user for investments
 */
contract SimpleInvestmentTestScript is Script {
    InvestmentEngine public investmentEngine;
    PlanManager public planManager;

    // Mock token addresses
    address constant USDC_ADDRESS = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1;
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy contracts
        console.log("=== Deploying Contracts ===");
        planManager = new PlanManager();
        investmentEngine = new InvestmentEngine();
        investmentEngine.setPlanManager(address(planManager));
        console.log("Contracts deployed and configured");

        // Create a test plan
        createTestPlan();

        // Test deposits (as script owner)
        testDeposits();

        // Test investments
        testInvestments();

        // Test view functions
        testViewFunctions();

        vm.stopBroadcast();
    }

    function createTestPlan() internal {
        console.log("\n=== Creating Test Plan ===");

        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](2);
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 6000, // 60%
            minPercentage: 5500,
            maxPercentage: 6500
        });
        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,
            maxPercentage: 4500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Test Conservative Plan",
            allocations
        );
        console.log("Created plan with ID:", planId);

        IPlanManager.InvestmentPlan memory plan = planManager.getPlan(planId);
        console.log("Plan risk score:", plan.riskScore);
    }

    function testDeposits() internal {
        console.log("\n=== Testing Deposits ===");

        address scriptUser = msg.sender; // This is the script's address
        console.log("Script user address:", scriptUser);

        // Since we can't call deposit() directly (it doesn't exist without amount),
        // we'll use depositForUser to deposit for ourselves
        console.log("Initial balance:");
        logUserBalance(scriptUser);

        // Make deposits for the script user
        investmentEngine.depositForUser(scriptUser, 1000, IInvestmentEngine.DepositType.Manual);
        console.log("After manual deposit of 1000:");
        logUserBalance(scriptUser);

        investmentEngine.depositForUser(scriptUser, 2000, IInvestmentEngine.DepositType.Salary);
        console.log("After salary deposit of 2000:");
        logUserBalance(scriptUser);

        investmentEngine.depositForUser(scriptUser, 500, IInvestmentEngine.DepositType.EmployerMatch);
        console.log("After employer match of 500:");
        logUserBalance(scriptUser);

        console.log("Total deposits completed. Final balance:");
        logUserBalance(scriptUser);
    }

    function testInvestments() internal {
        console.log("\n=== Testing Investments ===");

        address scriptUser = msg.sender;

        // Now we can call invest() as it will use msg.sender (script address)
        console.log("Creating investment...");
        uint256 investmentId = investmentEngine.invest(1, 1500); // Plan 1, amount 1500
        console.log("Created investment with ID:", investmentId);

        console.log("Balance after investment creation:");
        logUserBalance(scriptUser);

        // Check investment details
        IInvestmentEngine.Investment memory investment = investmentEngine.getInvestment(investmentId);
        console.log("Investment details:");
        console.log("  User:", investment.user);
        console.log("  Plan ID:", investment.planId);
        console.log("  Amount:", investment.totalAmount);
        console.log("  Status:", uint256(investment.status)); // 0=Pending, 1=Executed, 2=Failed

        // Execute the investment
        console.log("Executing investment...");
        investmentEngine.executeInvestment(investmentId);

        console.log("Balance after investment execution:");
        logUserBalance(scriptUser);

        // Check updated investment details
        investment = investmentEngine.getInvestment(investmentId);
        console.log("Updated investment status:", uint256(investment.status));
        console.log("Executed amount:", investment.executedAmount);

        // Create another investment
        console.log("\nCreating second investment...");
        uint256 investmentId2 = investmentEngine.invest(1, 800);
        console.log("Created second investment with ID:", investmentId2);

        console.log("Final balance:");
        logUserBalance(scriptUser);
    }

    function testViewFunctions() internal view {
        console.log("\n=== Testing View Functions ===");

        address scriptUser = tx.origin; // Get the original sender

        // Test getUserDeposits
        IInvestmentEngine.UserDeposit[] memory deposits = investmentEngine.getUserDeposits(scriptUser);
        console.log("Total deposits:", deposits.length);

        if (deposits.length > 0) {
            console.log("First deposit details:");
            console.log("  Amount:", deposits[0].amount);
            console.log("  Type:", uint256(deposits[0].depositType));
            console.log("  Processed:", deposits[0].processed);
        }

        // Test getUserInvestments
        IInvestmentEngine.Investment[] memory investments = investmentEngine.getUserInvestments(scriptUser);
        console.log("Total investments:", investments.length);

        // Count by status
        uint256 pendingCount = 0;
        uint256 executedCount = 0;
        for (uint256 i = 0; i < investments.length; i++) {
            if (investments[i].status == IInvestmentEngine.InvestmentStatus.Pending) {
                pendingCount++;
            } else if (investments[i].status == IInvestmentEngine.InvestmentStatus.Executed) {
                executedCount++;
            }
        }
        console.log("Pending investments:", pendingCount);
        console.log("Executed investments:", executedCount);

        // Test getPendingInvestments
        IInvestmentEngine.Investment[] memory pending = investmentEngine.getPendingInvestments(scriptUser);
        console.log("Pending investments (direct query):", pending.length);

        // Test portfolio value
        uint256 portfolioValue = investmentEngine.getUserPortfolioValue(scriptUser);
        console.log("Portfolio value:", portfolioValue);

        // Test total value locked
        uint256 tvl = investmentEngine.getTotalValueLocked();
        console.log("Total Value Locked:", tvl);

        // Administrative info
        console.log("\n=== Contract Configuration ===");
        console.log("InvestmentEngine owner:", investmentEngine.owner());
        console.log("Plan Manager address:", investmentEngine.planManager());
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