// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/InvestmentEngineV3.sol";
import "../src/PlanManager.sol";
import "../src/tokens/MockERC20.sol";
import "../src/mocks/MockUniswapV4Router.sol";
import "../src/mocks/MockPyth.sol";
import "../src/interfaces/IPlanManager.sol";

/**
 * @title InvestmentEngineV3IntegrationTest
 * @dev Comprehensive test suite for InvestmentEngineV3 with Uniswap V4 integration
 * Tests all functionality: V4 swaps, portfolio creation, error handling, edge cases
 */
contract InvestmentEngineV3IntegrationTest is Test {
    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/

    InvestmentEngineV3Simple public investmentEngine;
    PlanManager public planManager;
    MockUniswapV4Router public mockRouter;
    MockPyth public mockPyth;

    /*//////////////////////////////////////////////////////////////
                               TOKENS
    //////////////////////////////////////////////////////////////*/

    MockERC20 public usdc;
    MockERC20 public wbtc;
    MockERC20 public weth;
    MockERC20 public link;

    /*//////////////////////////////////////////////////////////////
                               TEST USERS
    //////////////////////////////////////////////////////////////*/

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public admin = address(this);

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 constant INITIAL_BALANCE = 100000 * 10**6; // 100,000 USDC
    uint256 constant INVESTMENT_AMOUNT = 5000 * 10**6;  // 5,000 USDC
    uint256 constant SMALL_INVESTMENT = 100 * 10**6;    // 100 USDC
    uint256 constant LARGE_INVESTMENT = 50000 * 10**6;  // 50,000 USDC

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event TestSuiteStarted(string suiteName);
    event TestSuiteCompleted(string suiteName, bool success);
    event TestCaseResult(string testName, bool passed, string details);

    /*//////////////////////////////////////////////////////////////
                               SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        console.log("==========================================");
        console.log("INVESTMENT ENGINE V3 - INTEGRATION TESTS");
        console.log("==========================================");

        deployContracts();
        setupTokens();
        setupExchangeRates();
        fundUsers();
        createTestPlans();

        console.log("Setup completed successfully");
        console.log("==========================================");
    }

    function deployContracts() internal {
        console.log("Deploying contracts...");

        // Deploy tokens
        usdc = new MockERC20("USD Coin", "USDC", 6, 10000000 * 10**6, 10000 * 10**6);
        wbtc = new MockERC20("Wrapped Bitcoin", "WBTC", 8, 1000 * 10**8, 10 * 10**6);
        weth = new MockERC20("Wrapped Ether", "WETH", 18, 100000 * 10**18, 100 * 10**18);
        link = new MockERC20("Chainlink", "LINK", 18, 1000000 * 10**18, 1000 * 10**18);

        // Deploy core contracts
        planManager = new PlanManager();
        mockRouter = new MockUniswapV4Router();
        mockPyth = new MockPyth();
        investmentEngine = new InvestmentEngineV3Simple(
            address(planManager),
            address(mockRouter),
            address(usdc),
            address(mockPyth)
        );

        console.log("Contracts deployed successfully");
    }

    function setupTokens() internal {
        console.log("Setting up token liquidity...");

        // Fund mock router with tokens for swaps
        usdc.mint(address(mockRouter), 1000000 * 10**6);  // 1M USDC
        wbtc.mint(address(mockRouter), 100 * 10**8);      // 100 WBTC
        weth.mint(address(mockRouter), 1000 * 10**18);    // 1K WETH
        link.mint(address(mockRouter), 100000 * 10**18);  // 100K LINK

        console.log("Token liquidity established");
    }

    function setupExchangeRates() internal {
        console.log("Setting up exchange rates...");

        // Set realistic exchange rates (scaled by 1e18)
        mockRouter.setExchangeRate(address(usdc), address(usdc), 1e18);      // 1:1
        mockRouter.setExchangeRate(address(usdc), address(wbtc), 2e13); // 1 USDC = 0.00002 WBTC (~$50k BTC)
        mockRouter.setExchangeRate(address(usdc), address(weth), 3e17);  // 1 USDC = 0.3 WETH (~$3.33 USDC per ETH)
        mockRouter.setExchangeRate(address(usdc), address(link), 5e16);    // 1 USDC = 0.05 LINK (~$20 USDC per LINK)

        console.log("Exchange rates configured");
    }

    function fundUsers() internal {
        console.log("Funding test users...");

        usdc.mint(alice, INITIAL_BALANCE);
        usdc.mint(bob, INITIAL_BALANCE);
        usdc.mint(charlie, INITIAL_BALANCE);

        console.log("Users funded successfully");
    }

    function createTestPlans() internal {
        console.log("Creating test investment plans...");

        // Conservative Plan (70% USDC, 30% WETH)
        IPlanManager.AssetAllocation[] memory conservativeAllocations = new IPlanManager.AssetAllocation[](2);
        conservativeAllocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: address(usdc),
            targetPercentage: 7000,
            minPercentage: 6500,
            maxPercentage: 7500
        });
        conservativeAllocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(weth),
            targetPercentage: 3000,
            minPercentage: 2500,
            maxPercentage: 3500
        });

        planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative Portfolio",
            conservativeAllocations
        );

        // Balanced Plan (40% WETH, 30% WBTC, 30% USDC)
        IPlanManager.AssetAllocation[] memory balancedAllocations = new IPlanManager.AssetAllocation[](3);
        balancedAllocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(weth),
            targetPercentage: 4000,
            minPercentage: 3500,
            maxPercentage: 4500
        });
        balancedAllocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(wbtc),
            targetPercentage: 3000,
            minPercentage: 2500,
            maxPercentage: 3500
        });
        balancedAllocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: address(usdc),
            targetPercentage: 3000,
            minPercentage: 2500,
            maxPercentage: 3500
        });

        planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Balanced Portfolio",
            balancedAllocations
        );

        // Aggressive Plan (35% WETH, 30% WBTC, 25% LINK, 10% USDC)
        IPlanManager.AssetAllocation[] memory aggressiveAllocations = new IPlanManager.AssetAllocation[](4);
        aggressiveAllocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(weth),
            targetPercentage: 3500,
            minPercentage: 3000,
            maxPercentage: 4000
        });
        aggressiveAllocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(wbtc),
            targetPercentage: 3000,
            minPercentage: 2500,
            maxPercentage: 3500
        });
        aggressiveAllocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(link),
            targetPercentage: 2500,
            minPercentage: 2000,
            maxPercentage: 3000
        });
        aggressiveAllocations[3] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: address(usdc),
            targetPercentage: 1000,
            minPercentage: 500,
            maxPercentage: 1500
        });

        planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "Aggressive Portfolio",
            aggressiveAllocations
        );

        console.log("Test plans created successfully");
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SUITE 1: BASIC FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    function test_BasicFunctionality() public {
        emit TestSuiteStarted("Basic Functionality");
        bool allPassed = true;

        allPassed = allPassed && testContractInitialization();
        allPassed = allPassed && testValidInvestment();
        allPassed = allPassed && testTokenDelivery();
        allPassed = allPassed && testInvestmentTracking();

        emit TestSuiteCompleted("Basic Functionality", allPassed);
        assertTrue(allPassed, "Basic Functionality suite failed");
    }

    function testContractInitialization() internal returns (bool) {
        bool success = investmentEngine.owner() == admin &&
                      investmentEngine.planManager() == address(planManager) &&
                      address(investmentEngine.router()) == address(mockRouter) &&
                      investmentEngine.baseToken() == address(usdc) &&
                      investmentEngine.fee() == 3000 &&
                      investmentEngine.slippage() == 500;

        emit TestCaseResult("Contract Initialization", success, success ? "All parameters correct" : "Initialization failed");
        return success;
    }

    function testValidInvestment() internal returns (bool) {
        vm.startPrank(alice);

        // Approve tokens
        usdc.approve(address(investmentEngine), INVESTMENT_AMOUNT);

        // Record initial balance
        uint256 initialBalance = usdc.balanceOf(alice);

        // Make investment
        uint256 investmentId = investmentEngine.depositAndInvest(INVESTMENT_AMOUNT, 1); // Conservative plan

        vm.stopPrank();

        // Verify investment was created
        InvestmentEngineV3Simple.Investment memory investment = investmentEngine.getInvestment(investmentId);
        bool success = investment.user == alice &&
                      investment.planId == 1 &&
                      investment.amount == INVESTMENT_AMOUNT &&
                      investmentId == 1;

        // Verify USDC was deducted (alice should have received some back due to allocation)
        uint256 finalBalance = usdc.balanceOf(alice);
        success = success && (finalBalance < initialBalance); // Balance should be less than initial

        emit TestCaseResult("Valid Investment", success, success ? "Investment created successfully" : "Investment creation failed");
        return success;
    }

    function testTokenDelivery() internal returns (bool) {
        // Alice should have received tokens from the conservative plan
        uint256 usdcBalance = usdc.balanceOf(alice);
        uint256 wethBalance = weth.balanceOf(alice);

        // Conservative plan: 70% USDC, 30% WETH
        bool hasUsdc = usdcBalance > 0;
        bool hasWeth = wethBalance > 0;

        bool success = hasUsdc && hasWeth;

        emit TestCaseResult("Token Delivery", success, success ? "Tokens delivered to user" : "Token delivery failed");
        return success;
    }

    function testInvestmentTracking() internal returns (bool) {
        uint256 totalInvestments = investmentEngine.getTotalInvestments();
        bool success = totalInvestments == 1;

        emit TestCaseResult("Investment Tracking", success, success ? "Investment counter works" : "Investment tracking failed");
        return success;
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SUITE 2: PORTFOLIO CREATION
    //////////////////////////////////////////////////////////////*/

    function test_PortfolioCreation() public {
        emit TestSuiteStarted("Portfolio Creation");
        bool allPassed = true;

        allPassed = allPassed && testConservativePortfolio();
        allPassed = allPassed && testBalancedPortfolio();
        allPassed = allPassed && testAggressivePortfolio();
        allPassed = allPassed && testMultipleInvestments();

        emit TestSuiteCompleted("Portfolio Creation", allPassed);
        assertTrue(allPassed, "Portfolio Creation suite failed");
    }

    function testConservativePortfolio() internal returns (bool) {
        vm.startPrank(bob);

        usdc.approve(address(investmentEngine), INVESTMENT_AMOUNT);
        uint256 investmentId = investmentEngine.depositAndInvest(INVESTMENT_AMOUNT, 1);

        vm.stopPrank();

        // Check allocation approximates 70% USDC, 30% WETH
        uint256 usdcReceived = usdc.balanceOf(bob);
        uint256 wethReceived = weth.balanceOf(bob);

        // Allow for some variance due to slippage and exchange rates
        uint256 expectedUsdc = (INVESTMENT_AMOUNT * 7000) / 10000;
        uint256 usdcVariance = expectedUsdc > usdcReceived ? expectedUsdc - usdcReceived : usdcReceived - expectedUsdc;

        bool success = usdcReceived > 0 && wethReceived > 0 && usdcVariance < (expectedUsdc / 10); // Within 10%

        emit TestCaseResult("Conservative Portfolio", success, success ? "Portfolio allocation correct" : "Portfolio allocation incorrect");
        return success;
    }

    function testBalancedPortfolio() internal returns (bool) {
        vm.startPrank(charlie);

        usdc.approve(address(investmentEngine), INVESTMENT_AMOUNT);
        uint256 investmentId = investmentEngine.depositAndInvest(INVESTMENT_AMOUNT, 2); // Balanced plan

        vm.stopPrank();

        // Check that charlie received 3 different tokens (WETH, WBTC, USDC)
        uint256 usdcBalance = usdc.balanceOf(charlie);
        uint256 wethBalance = weth.balanceOf(charlie);
        uint256 wbtcBalance = wbtc.balanceOf(charlie);

        bool success = usdcBalance > 0 && wethBalance > 0 && wbtcBalance > 0;

        emit TestCaseResult("Balanced Portfolio", success, success ? "Multi-token portfolio created" : "Multi-token portfolio failed");
        return success;
    }

    function testAggressivePortfolio() internal returns (bool) {
        address david = makeAddr("david");
        usdc.mint(david, INITIAL_BALANCE);

        vm.startPrank(david);

        usdc.approve(address(investmentEngine), INVESTMENT_AMOUNT);
        uint256 investmentId = investmentEngine.depositAndInvest(INVESTMENT_AMOUNT, 3); // Aggressive plan

        vm.stopPrank();

        // Check that david received 4 different tokens (WETH, WBTC, LINK, USDC)
        uint256 usdcBalance = usdc.balanceOf(david);
        uint256 wethBalance = weth.balanceOf(david);
        uint256 wbtcBalance = wbtc.balanceOf(david);
        uint256 linkBalance = link.balanceOf(david);

        bool success = usdcBalance > 0 && wethBalance > 0 && wbtcBalance > 0 && linkBalance > 0;

        emit TestCaseResult("Aggressive Portfolio", success, success ? "4-token portfolio created" : "4-token portfolio failed");
        return success;
    }

    function testMultipleInvestments() internal returns (bool) {
        address eve = makeAddr("eve");
        usdc.mint(eve, INITIAL_BALANCE);

        vm.startPrank(eve);

        // Make two investments
        usdc.approve(address(investmentEngine), SMALL_INVESTMENT * 2);
        uint256 investment1 = investmentEngine.depositAndInvest(SMALL_INVESTMENT, 1);
        uint256 investment2 = investmentEngine.depositAndInvest(SMALL_INVESTMENT, 2);

        vm.stopPrank();

        bool success = investment1 != investment2 &&
                      investmentEngine.getTotalInvestments() >= 4; // Previous tests + these 2

        emit TestCaseResult("Multiple Investments", success, success ? "Multiple investments tracked" : "Multiple investments failed");
        return success;
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SUITE 3: ERROR HANDLING
    //////////////////////////////////////////////////////////////*/

    function test_ErrorHandling() public {
        emit TestSuiteStarted("Error Handling");
        bool allPassed = true;

        allPassed = allPassed && testInvalidPlan();
        allPassed = allPassed && testZeroAmount();
        allPassed = allPassed && testInsufficientApproval();
        allPassed = allPassed && testSwapFailureRecovery();

        emit TestSuiteCompleted("Error Handling", allPassed);
        assertTrue(allPassed, "Error Handling suite failed");
    }

    function testInvalidPlan() internal returns (bool) {
        vm.startPrank(alice);

        usdc.approve(address(investmentEngine), INVESTMENT_AMOUNT);

        try investmentEngine.depositAndInvest(INVESTMENT_AMOUNT, 999) {
            emit TestCaseResult("Invalid Plan", false, "Should have reverted");
            return false;
        } catch {
            emit TestCaseResult("Invalid Plan", true, "Correctly rejected invalid plan");
            return true;
        }

        vm.stopPrank();
    }

    function testZeroAmount() internal returns (bool) {
        vm.startPrank(alice);

        try investmentEngine.depositAndInvest(0, 1) {
            emit TestCaseResult("Zero Amount", false, "Should have reverted");
            return false;
        } catch {
            emit TestCaseResult("Zero Amount", true, "Correctly rejected zero amount");
            return true;
        }

        vm.stopPrank();
    }

    function testInsufficientApproval() internal returns (bool) {
        vm.startPrank(alice);

        // Don't approve enough tokens
        usdc.approve(address(investmentEngine), INVESTMENT_AMOUNT / 2);

        try investmentEngine.depositAndInvest(INVESTMENT_AMOUNT, 1) {
            emit TestCaseResult("Insufficient Approval", false, "Should have reverted");
            return false;
        } catch {
            emit TestCaseResult("Insufficient Approval", true, "Correctly rejected insufficient approval");
            return true;
        }

        vm.stopPrank();
    }

    function testSwapFailureRecovery() internal returns (bool) {
        // Set router to fail swaps for WETH
        mockRouter.setShouldFailSwap(address(weth), true);

        address frank = makeAddr("frank");
        usdc.mint(frank, INITIAL_BALANCE);

        vm.startPrank(frank);

        usdc.approve(address(investmentEngine), INVESTMENT_AMOUNT);
        uint256 initialBalance = usdc.balanceOf(frank);

        // This should succeed but fallback to USDC for failed swaps
        uint256 investmentId = investmentEngine.depositAndInvest(INVESTMENT_AMOUNT, 1);

        vm.stopPrank();

        // Reset router
        mockRouter.setShouldFailSwap(address(weth), false);

        // Frank should have received all tokens as USDC due to swap failure
        uint256 finalBalance = usdc.balanceOf(frank);
        uint256 wethBalance = weth.balanceOf(frank);

        // Should have some USDC back (from failed swap fallback) and no WETH
        bool success = finalBalance > initialBalance - INVESTMENT_AMOUNT && wethBalance == 0;

        emit TestCaseResult("Swap Failure Recovery", success, success ? "Fallback mechanism worked" : "Fallback mechanism failed");
        return success;
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SUITE 4: ADMINISTRATIVE
    //////////////////////////////////////////////////////////////*/

    function test_Administrative() public {
        emit TestSuiteStarted("Administrative Functions");
        bool allPassed = true;

        allPassed = allPassed && testSlippageConfiguration();
        allPassed = allPassed && testRouterConfiguration();
        allPassed = allPassed && testPlanManagerConfiguration();
        allPassed = allPassed && testOwnershipControls();

        emit TestSuiteCompleted("Administrative Functions", allPassed);
        assertTrue(allPassed, "Administrative Functions suite failed");
    }

    function testSlippageConfiguration() internal returns (bool) {
        // Test setting valid slippage
        investmentEngine.setSlippage(1000); // 10%
        bool success = investmentEngine.slippage() == 1000;

        // Test invalid slippage (should revert)
        try investmentEngine.setSlippage(2500) { // 25% > 20% max
            success = false;
        } catch {
            // Expected to revert
        }

        emit TestCaseResult("Slippage Configuration", success, success ? "Slippage controls work" : "Slippage controls failed");
        return success;
    }

    function testRouterConfiguration() internal returns (bool) {
        address newRouter = makeAddr("newRouter");
        investmentEngine.setRouter(newRouter);
        bool success = address(investmentEngine.router()) == newRouter;

        // Reset for other tests
        investmentEngine.setRouter(address(mockRouter));

        emit TestCaseResult("Router Configuration", success, success ? "Router update works" : "Router update failed");
        return success;
    }

    function testPlanManagerConfiguration() internal returns (bool) {
        address newPlanManager = makeAddr("newPlanManager");
        investmentEngine.setPlanManager(newPlanManager);
        bool success = investmentEngine.planManager() == newPlanManager;

        // Reset for other tests
        investmentEngine.setPlanManager(address(planManager));

        emit TestCaseResult("Plan Manager Configuration", success, success ? "Plan manager update works" : "Plan manager update failed");
        return success;
    }

    function testOwnershipControls() internal returns (bool) {
        // Test non-owner access
        vm.startPrank(alice);

        try investmentEngine.setSlippage(1000) {
            emit TestCaseResult("Ownership Controls", false, "Non-owner should not have access");
            return false;
        } catch {
            // Expected to revert
        }

        vm.stopPrank();

        emit TestCaseResult("Ownership Controls", true, "Ownership controls work correctly");
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SUITE 5: INTEGRATION
    //////////////////////////////////////////////////////////////*/

    function test_Integration() public {
        emit TestSuiteStarted("System Integration");
        bool allPassed = true;

        allPassed = allPassed && testEndToEndFlow();
        allPassed = allPassed && testHighVolumeInvestments();
        allPassed = allPassed && testEdgeCaseAmounts();

        emit TestSuiteCompleted("System Integration", allPassed);
        assertTrue(allPassed, "System Integration suite failed");
    }

    function testEndToEndFlow() internal returns (bool) {
        address grace = makeAddr("grace");
        usdc.mint(grace, INITIAL_BALANCE);

        vm.startPrank(grace);

        // Complete flow: approve -> invest -> verify
        usdc.approve(address(investmentEngine), INVESTMENT_AMOUNT);
        uint256 investmentId = investmentEngine.depositAndInvest(INVESTMENT_AMOUNT, 2);

        vm.stopPrank();

        // Verify all aspects
        InvestmentEngineV3Simple.Investment memory investment = investmentEngine.getInvestment(investmentId);
        bool investmentCorrect = investment.user == grace && investment.amount == INVESTMENT_AMOUNT;

        uint256 usdcBalance = usdc.balanceOf(grace);
        uint256 wethBalance = weth.balanceOf(grace);
        uint256 wbtcBalance = wbtc.balanceOf(grace);
        bool tokensReceived = usdcBalance > 0 && wethBalance > 0 && wbtcBalance > 0;

        bool success = investmentCorrect && tokensReceived;

        emit TestCaseResult("End-to-End Flow", success, success ? "Complete flow successful" : "Complete flow failed");
        return success;
    }

    function testHighVolumeInvestments() internal returns (bool) {
        address whale = makeAddr("whale");
        usdc.mint(whale, LARGE_INVESTMENT * 2);

        vm.startPrank(whale);

        usdc.approve(address(investmentEngine), LARGE_INVESTMENT);
        uint256 investmentId = investmentEngine.depositAndInvest(LARGE_INVESTMENT, 3);

        vm.stopPrank();

        // Verify large investment was processed
        InvestmentEngineV3Simple.Investment memory investment = investmentEngine.getInvestment(investmentId);
        bool success = investment.amount == LARGE_INVESTMENT && investment.user == whale;

        emit TestCaseResult("High Volume Investments", success, success ? "Large investment processed" : "Large investment failed");
        return success;
    }

    function testEdgeCaseAmounts() internal returns (bool) {
        address henry = makeAddr("henry");
        usdc.mint(henry, INITIAL_BALANCE);

        vm.startPrank(henry);

        // Test very small amount (1 USDC)
        uint256 tinyAmount = 1 * 10**6;
        usdc.approve(address(investmentEngine), tinyAmount);
        uint256 investmentId = investmentEngine.depositAndInvest(tinyAmount, 1);

        vm.stopPrank();

        // Verify tiny investment worked
        InvestmentEngineV3Simple.Investment memory investment = investmentEngine.getInvestment(investmentId);
        bool success = investment.amount == tinyAmount;

        emit TestCaseResult("Edge Case Amounts", success, success ? "Tiny investment processed" : "Tiny investment failed");
        return success;
    }

    /*//////////////////////////////////////////////////////////////
                               COMPREHENSIVE SUMMARY
    //////////////////////////////////////////////////////////////*/

    function test_ComprehensiveSummary() public {
        console.log("\n==========================================");
        console.log("INVESTMENT ENGINE V3 - TEST SUMMARY");
        console.log("==========================================");

        // Run all test suites
        test_BasicFunctionality();
        test_PortfolioCreation();
        test_ErrorHandling();
        test_Administrative();
        test_Integration();

        // Print final summary
        console.log("\n==========================================");
        console.log("FINAL SYSTEM STATUS");
        console.log("==========================================");

        console.log("Total Investments:", investmentEngine.getTotalInvestments());
        console.log("Contract Owner:", investmentEngine.owner());
        console.log("Router Address:", address(investmentEngine.router()));
        console.log("Base Token:", investmentEngine.baseToken());
        console.log("Current Slippage:", investmentEngine.slippage());

        console.log("\n==========================================");
        console.log("UNISWAP V4 INTEGRATION TESTS COMPLETED!");
        console.log("INVESTMENT ENGINE V3 READY FOR DEPLOYMENT");
        console.log("==========================================");
    }
}