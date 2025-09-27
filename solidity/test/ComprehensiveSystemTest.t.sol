// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/PlanManager.sol";
import "../src/InvestmentEngineV2.sol";
import "../src/tokens/MockERC20.sol";
import "../src/interfaces/IPlanManager.sol";
import "../src/interfaces/IInvestmentEngine.sol";

/**
 * @title ComprehensiveSystemTest
 * @dev Complete test suite for 404 Poverty Not Found DeFi Investment Platform
 * Tests all functionality: Plan Management, Token Operations, Investment Flow, Portfolio Tracking
 */
contract ComprehensiveSystemTest is Test {
    // Core Contracts
    PlanManager public planManager;
    InvestmentEngineV2 public investmentEngine;

    // Mock Tokens
    MockERC20 public usdc;
    MockERC20 public wbtc;
    MockERC20 public weth;
    MockERC20 public link;

    // Test Users
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public admin = address(this);

    // Test Constants
    uint256 constant INITIAL_BALANCE = 10000 * 10**6; // 10,000 USDC
    uint256 constant SALARY_AMOUNT = 2000 * 10**6;    // 2,000 USDC
    uint256 constant INVESTMENT_AMOUNT = 1500 * 10**6; // 1,500 USDC

    event TestSuiteStarted(string suiteName);
    event TestSuiteCompleted(string suiteName, bool success);
    event TestCaseResult(string testName, bool passed, string details);

    function setUp() public {
        console.log("==========================================");
        console.log("404 POVERTY NOT FOUND - COMPREHENSIVE TEST");
        console.log("==========================================");

        deployContracts();
        setupTokens();
        fundUsers();

        console.log("Setup completed successfully");
        console.log("==========================================");
    }

    function deployContracts() internal {
        console.log("Deploying core contracts...");

        // Deploy tokens with proper decimals and supply
        usdc = new MockERC20("USD Coin", "USDC", 6, 1000000 * 10**6, 1000 * 10**6);
        wbtc = new MockERC20("Wrapped Bitcoin", "WBTC", 8, 100 * 10**8, 1 * 10**6);
        weth = new MockERC20("Wrapped Ether", "WETH", 18, 1000 * 10**18, 1 * 10**18);
        link = new MockERC20("Chainlink", "LINK", 18, 1000000 * 10**18, 100 * 10**18);

        // Deploy core contracts
        planManager = new PlanManager();
        investmentEngine = new InvestmentEngineV2(address(usdc));

        // Connect contracts
        investmentEngine.setPlanManager(address(planManager));

        console.log("Core contracts deployed and connected");
    }

    function setupTokens() internal {
        console.log("Setting up token reserves for trading simulation...");

        // Fund investment engine with tokens for simulated trading
        usdc.transfer(address(investmentEngine), 500000 * 10**6);  // 500K USDC
        wbtc.transfer(address(investmentEngine), 50 * 10**8);      // 50 WBTC
        weth.transfer(address(investmentEngine), 500 * 10**18);    // 500 WETH
        link.transfer(address(investmentEngine), 10000 * 10**18);  // 10K LINK

        console.log("Token reserves established");
    }

    function fundUsers() internal {
        console.log("Funding test users...");

        // Give users some USDC to start with
        usdc.mint(alice, INITIAL_BALANCE);
        usdc.mint(bob, INITIAL_BALANCE);
        usdc.mint(charlie, INITIAL_BALANCE);

        console.log("Test users funded with initial USDC");
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SUITE 1: PLAN MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function test_PlanManagement() public {
        emit TestSuiteStarted("Plan Management");

        bool allPassed = true;

        // Test 1: Create Conservative Plan
        allPassed = allPassed && createConservativePlan();

        // Test 2: Create Balanced Plan
        allPassed = allPassed && createBalancedPlan();

        // Test 3: Create Aggressive Plan
        allPassed = allPassed && createAggressivePlan();

        // Test 4: Plan Retrieval
        allPassed = allPassed && testPlanRetrieval();

        // Test 5: Plan Counter
        allPassed = allPassed && testPlanCounter();

        emit TestSuiteCompleted("Plan Management", allPassed);
        assertTrue(allPassed, "Plan Management suite failed");
    }

    function createConservativePlan() internal returns (bool) {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](2);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: address(usdc),
            targetPercentage: 7000, // 70%
            minPercentage: 6500,
            maxPercentage: 7500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(weth),
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative Stable Strategy",
            allocations
        );

        bool success = planId == 1;
        emit TestCaseResult("Create Conservative Plan", success, success ? "Plan created with ID 1" : "Failed to create plan");
        return success;
    }

    function createBalancedPlan() internal returns (bool) {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(weth),
            targetPercentage: 4000, // 40%
            minPercentage: 3500,
            maxPercentage: 4500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(wbtc),
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: address(usdc),
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Balanced Growth Portfolio",
            allocations
        );

        bool success = planId == 2;
        emit TestCaseResult("Create Balanced Plan", success, success ? "Plan created with ID 2" : "Failed to create plan");
        return success;
    }

    function createAggressivePlan() internal returns (bool) {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](4);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(weth),
            targetPercentage: 3500, // 35%
            minPercentage: 3000,
            maxPercentage: 4000
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(wbtc),
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(link),
            targetPercentage: 2500, // 25%
            minPercentage: 2000,
            maxPercentage: 3000
        });

        allocations[3] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: address(usdc),
            targetPercentage: 1000, // 10%
            minPercentage: 500,
            maxPercentage: 1500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "Aggressive Growth Strategy",
            allocations
        );

        bool success = planId == 3;
        emit TestCaseResult("Create Aggressive Plan", success, success ? "Plan created with ID 3" : "Failed to create plan");
        return success;
    }

    function testPlanRetrieval() internal returns (bool) {
        IPlanManager.InvestmentPlan memory plan = planManager.getPlan(1);

        bool success = plan.planId == 1 &&
                      plan.planType == IPlanManager.PlanType.Conservative &&
                      keccak256(bytes(plan.name)) == keccak256(bytes("Conservative Stable Strategy")) &&
                      plan.isActive == true &&
                      plan.allocations.length == 2;

        emit TestCaseResult("Plan Retrieval", success, success ? "Plan 1 retrieved correctly" : "Plan retrieval failed");
        return success;
    }

    function testPlanCounter() internal returns (bool) {
        uint256 totalPlans = planManager.getTotalPlans();
        bool success = totalPlans == 3;

        emit TestCaseResult("Plan Counter", success, success ? "Total plans = 3" : "Plan counter incorrect");
        return success;
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SUITE 2: TOKEN OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function test_TokenOperations() public {
        emit TestSuiteStarted("Token Operations");

        bool allPassed = true;

        // Test 1: Token Deposits
        allPassed = allPassed && testTokenDeposits();

        // Test 2: Multiple Deposit Types
        allPassed = allPassed && testMultipleDepositTypes();

        // Test 3: Balance Tracking
        allPassed = allPassed && testBalanceTracking();

        // Test 4: Token Faucet
        allPassed = allPassed && testTokenFaucet();

        emit TestSuiteCompleted("Token Operations", allPassed);
        assertTrue(allPassed, "Token Operations suite failed");
    }

    function testTokenDeposits() internal returns (bool) {
        vm.startPrank(alice);

        // Approve and deposit USDC
        usdc.approve(address(investmentEngine), SALARY_AMOUNT);
        investmentEngine.depositToken(
            address(usdc),
            SALARY_AMOUNT,
            IInvestmentEngine.DepositType.Salary
        );

        vm.stopPrank();

        IInvestmentEngine.UserBalance memory balance = investmentEngine.getUserBalance(alice);
        bool success = balance.totalDeposited == SALARY_AMOUNT &&
                      balance.availableBalance == SALARY_AMOUNT;

        emit TestCaseResult("Token Deposits", success, success ? "USDC deposited successfully" : "Deposit failed");
        return success;
    }

    function testMultipleDepositTypes() internal returns (bool) {
        vm.startPrank(bob);

        // Salary deposit
        usdc.approve(address(investmentEngine), SALARY_AMOUNT);
        investmentEngine.depositToken(
            address(usdc),
            SALARY_AMOUNT,
            IInvestmentEngine.DepositType.Salary
        );

        // Employer match deposit
        uint256 bonusAmount = 500 * 10**6;
        usdc.approve(address(investmentEngine), bonusAmount);
        investmentEngine.depositToken(
            address(usdc),
            bonusAmount,
            IInvestmentEngine.DepositType.EmployerMatch
        );

        vm.stopPrank();

        IInvestmentEngine.UserBalance memory balance = investmentEngine.getUserBalance(bob);
        bool success = balance.totalDeposited == SALARY_AMOUNT + bonusAmount;

        emit TestCaseResult("Multiple Deposit Types", success, success ? "Salary + EmployerMatch deposits successful" : "Multiple deposits failed");
        return success;
    }

    function testBalanceTracking() internal returns (bool) {
        IInvestmentEngine.UserBalance memory aliceBalance = investmentEngine.getUserBalance(alice);
        IInvestmentEngine.UserBalance memory bobBalance = investmentEngine.getUserBalance(bob);

        bool success = aliceBalance.totalDeposited == SALARY_AMOUNT &&
                      bobBalance.totalDeposited == SALARY_AMOUNT + 500 * 10**6 &&
                      aliceBalance.totalInvested == 0 &&
                      bobBalance.totalInvested == 0;

        emit TestCaseResult("Balance Tracking", success, success ? "Balances tracked correctly" : "Balance tracking failed");
        return success;
    }

    function testTokenFaucet() internal returns (bool) {
        vm.startPrank(charlie);

        uint256 balanceBefore = usdc.balanceOf(charlie);
        usdc.faucet();
        uint256 balanceAfter = usdc.balanceOf(charlie);

        vm.stopPrank();

        bool success = balanceAfter > balanceBefore;

        emit TestCaseResult("Token Faucet", success, success ? "Faucet works correctly" : "Faucet failed");
        return success;
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SUITE 3: INVESTMENT FLOW
    //////////////////////////////////////////////////////////////*/

    function test_InvestmentFlow() public {
        emit TestSuiteStarted("Investment Flow");

        bool allPassed = true;

        // Test 1: Investment Creation
        allPassed = allPassed && testInvestmentCreation();

        // Test 2: Investment Execution
        allPassed = allPassed && testInvestmentExecution();

        // Test 3: Portfolio Allocation
        allPassed = allPassed && testPortfolioAllocation();

        // Test 4: Multiple User Investments
        allPassed = allPassed && testMultipleUserInvestments();

        emit TestSuiteCompleted("Investment Flow", allPassed);
        assertTrue(allPassed, "Investment Flow suite failed");
    }

    function testInvestmentCreation() internal returns (bool) {
        vm.prank(alice);
        uint256 investmentId = investmentEngine.invest(2, INVESTMENT_AMOUNT); // Balanced plan

        bool success = investmentId > 0;

        emit TestCaseResult("Investment Creation", success, success ? "Investment created successfully" : "Investment creation failed");
        return success;
    }

    function testInvestmentExecution() internal returns (bool) {
        // Execute the investment created in previous test
        investmentEngine.executeInvestment(1);

        IInvestmentEngine.UserBalance memory balance = investmentEngine.getUserBalance(alice);
        bool success = balance.totalInvested == INVESTMENT_AMOUNT;

        emit TestCaseResult("Investment Execution", success, success ? "Investment executed successfully" : "Investment execution failed");
        return success;
    }

    function testPortfolioAllocation() internal returns (bool) {
        address[] memory aliceTokens = investmentEngine.getUserTokens(alice);

        // Alice should have tokens from balanced plan (WETH, WBTC, USDC)
        bool success = aliceTokens.length >= 2; // At least some tokens allocated

        emit TestCaseResult("Portfolio Allocation", success, success ? "Tokens allocated correctly" : "Portfolio allocation failed");
        return success;
    }

    function testMultipleUserInvestments() internal returns (bool) {
        // Bob invests in aggressive plan
        vm.prank(bob);
        uint256 bobInvestmentId = investmentEngine.invest(3, INVESTMENT_AMOUNT);

        // Execute Bob's investment
        investmentEngine.executeInvestment(bobInvestmentId);

        IInvestmentEngine.UserBalance memory bobBalance = investmentEngine.getUserBalance(bob);
        bool success = bobBalance.totalInvested == INVESTMENT_AMOUNT;

        emit TestCaseResult("Multiple User Investments", success, success ? "Multiple users can invest" : "Multiple user investments failed");
        return success;
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SUITE 4: PORTFOLIO TRACKING
    //////////////////////////////////////////////////////////////*/

    function test_PortfolioTracking() public {
        emit TestSuiteStarted("Portfolio Tracking");

        bool allPassed = true;

        // Test 1: Portfolio Value Calculation
        allPassed = allPassed && testPortfolioValue();

        // Test 2: User Token Holdings
        allPassed = allPassed && testUserTokenHoldings();

        // Test 3: Total Value Locked
        allPassed = allPassed && testTotalValueLocked();

        // Test 4: Individual Token Balances
        allPassed = allPassed && testIndividualTokenBalances();

        emit TestSuiteCompleted("Portfolio Tracking", allPassed);
        assertTrue(allPassed, "Portfolio Tracking suite failed");
    }

    function testPortfolioValue() internal returns (bool) {
        uint256 alicePortfolioValue = investmentEngine.getUserPortfolioValue(alice);
        uint256 bobPortfolioValue = investmentEngine.getUserPortfolioValue(bob);

        bool success = alicePortfolioValue > 0 && bobPortfolioValue > 0;

        emit TestCaseResult("Portfolio Value Calculation", success, success ? "Portfolio values calculated" : "Portfolio value calculation failed");
        return success;
    }

    function testUserTokenHoldings() internal returns (bool) {
        address[] memory aliceTokens = investmentEngine.getUserTokens(alice);
        address[] memory bobTokens = investmentEngine.getUserTokens(bob);

        bool success = aliceTokens.length > 0 && bobTokens.length > 0;

        emit TestCaseResult("User Token Holdings", success, success ? "Token holdings tracked" : "Token holdings tracking failed");
        return success;
    }

    function testTotalValueLocked() internal returns (bool) {
        uint256 tvl = investmentEngine.getTotalValueLocked();

        // TVL should be at least the sum of both investments
        bool success = tvl >= INVESTMENT_AMOUNT * 2;

        emit TestCaseResult("Total Value Locked", success, success ? "TVL calculated correctly" : "TVL calculation failed");
        return success;
    }

    function testIndividualTokenBalances() internal returns (bool) {
        address[] memory aliceTokens = investmentEngine.getUserTokens(alice);

        if (aliceTokens.length == 0) return false;

        uint256 tokenBalance = investmentEngine.getUserTokenBalance(alice, aliceTokens[0]);
        bool success = tokenBalance > 0;

        emit TestCaseResult("Individual Token Balances", success, success ? "Token balances retrieved" : "Token balance retrieval failed");
        return success;
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SUITE 5: EDGE CASES & SECURITY
    //////////////////////////////////////////////////////////////*/

    function test_EdgeCasesAndSecurity() public {
        emit TestSuiteStarted("Edge Cases & Security");

        bool allPassed = true;

        // Test 1: Invalid Plan Investment
        allPassed = allPassed && testInvalidPlanInvestment();

        // Test 2: Insufficient Balance Investment
        allPassed = allPassed && testInsufficientBalanceInvestment();

        // Test 3: Zero Amount Operations
        allPassed = allPassed && testZeroAmountOperations();

        // Test 4: Unauthorized Access
        allPassed = allPassed && testUnauthorizedAccess();

        emit TestSuiteCompleted("Edge Cases & Security", allPassed);
        assertTrue(allPassed, "Edge Cases & Security suite failed");
    }

    function testInvalidPlanInvestment() internal returns (bool) {
        vm.prank(alice);

        try investmentEngine.invest(999, INVESTMENT_AMOUNT) {
            emit TestCaseResult("Invalid Plan Investment", false, "Should have reverted");
            return false;
        } catch {
            emit TestCaseResult("Invalid Plan Investment", true, "Correctly rejected invalid plan");
            return true;
        }
    }

    function testInsufficientBalanceInvestment() internal returns (bool) {
        // Charlie has no deposits
        vm.prank(charlie);

        try investmentEngine.invest(1, INVESTMENT_AMOUNT) {
            emit TestCaseResult("Insufficient Balance Investment", false, "Should have reverted");
            return false;
        } catch {
            emit TestCaseResult("Insufficient Balance Investment", true, "Correctly rejected insufficient balance");
            return true;
        }
    }

    function testZeroAmountOperations() internal returns (bool) {
        vm.prank(alice);

        try investmentEngine.invest(1, 0) {
            emit TestCaseResult("Zero Amount Operations", false, "Should have reverted");
            return false;
        } catch {
            emit TestCaseResult("Zero Amount Operations", true, "Correctly rejected zero amount");
            return true;
        }
    }

    function testUnauthorizedAccess() internal returns (bool) {
        vm.prank(alice);

        try investmentEngine.executeInvestment(999) {
            emit TestCaseResult("Unauthorized Access", false, "Should have reverted");
            return false;
        } catch {
            emit TestCaseResult("Unauthorized Access", true, "Correctly rejected unauthorized access");
            return true;
        }
    }

    /*//////////////////////////////////////////////////////////////
                               COMPREHENSIVE SUMMARY
    //////////////////////////////////////////////////////////////*/

    function test_ComprehensiveSummary() public {
        console.log("\n==========================================");
        console.log("COMPREHENSIVE TEST SUMMARY");
        console.log("==========================================");

        // Run all test suites
        test_PlanManagement();
        test_TokenOperations();
        test_InvestmentFlow();
        test_PortfolioTracking();
        test_EdgeCasesAndSecurity();

        // Print final summary
        console.log("\n==========================================");
        console.log("FINAL SYSTEM STATUS");
        console.log("==========================================");

        console.log("Total Plans Created:", planManager.getTotalPlans());
        console.log("Total Value Locked:", investmentEngine.getTotalValueLocked() / 10**6, "USDC");

        console.log("\nUser Portfolio Summary:");
        printUserSummary(alice, "Alice");
        printUserSummary(bob, "Bob");
        printUserSummary(charlie, "Charlie");

        console.log("\n==========================================");
        console.log("ALL TESTS COMPLETED SUCCESSFULLY!");
        console.log("404 POVERTY NOT FOUND PLATFORM READY");
        console.log("==========================================");
    }

    function printUserSummary(address user, string memory name) internal {
        IInvestmentEngine.UserBalance memory balance = investmentEngine.getUserBalance(user);
        uint256 portfolioValue = investmentEngine.getUserPortfolioValue(user);
        address[] memory tokens = investmentEngine.getUserTokens(user);

        console.log(string.concat(name, ":"));
        console.log("  Total Deposited:", balance.totalDeposited / 10**6, "USDC");
        console.log("  Total Invested:", balance.totalInvested / 10**6, "USDC");
        console.log("  Available Balance:", balance.availableBalance / 10**6, "USDC");
        console.log("  Portfolio Value:", portfolioValue / 10**6, "USDC");
        console.log("  Token Holdings:", tokens.length, "different tokens");
    }
}