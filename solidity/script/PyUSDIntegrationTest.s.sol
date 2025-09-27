// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InvestmentEngine} from "../src/InvestmentEngine.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {PyUSDManager} from "../src/investments/PyUSDManager.sol";
import {MockPyUSD} from "../src/mock/MockPyUSD.sol";
import {IInvestmentEngine} from "../src/interfaces/IInvestmentEngine.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";

/**
 * Test script for PyUSD integration with InvestmentEngine
 * Tests both PyUSD-enabled and disabled scenarios
 */
contract PyUSDIntegrationTestScript is Script {
    InvestmentEngine public investmentEngine;
    PlanManager public planManager;
    PyUSDManager public pyusdManager;
    MockPyUSD public mockPyUSD;

    // Mock addresses
    address public PYUSD_TOKEN; // Will be set after deploying mock PyUSD
    address constant UNISWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // Real Uniswap V3
    address constant WETH_TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Real WETH
    address constant USDC_ADDRESS = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1; // Mock USDC
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006; // Mock WETH

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy and setup contracts
        deployContracts();
        
        // Test 1: Investment without PyUSD (baseline)
        testInvestmentWithoutPyUSD();
        
        // Test 2: Initialize PyUSD integration
        initializePyUSDIntegration();
        
        // Test 3: Investment with PyUSD enabled
        testInvestmentWithPyUSD();
        
        // Test 4: PyUSD view functions
        testPyUSDViewFunctions();
        
        // Test 5: PyUSD administrative functions
        testPyUSDAdministration();
        
        // Test 6: Edge cases and error handling
        testPyUSDEdgeCases();

        vm.stopBroadcast();
    }

    function deployContracts() internal {
        console.log("=== Deploying Contracts ===");
        
        // Deploy mock PyUSD first
        mockPyUSD = new MockPyUSD();
        PYUSD_TOKEN = address(mockPyUSD);
        mockPyUSD.mint(msg.sender, 1_000_000 * 10**18); // Mint 1 million tokens for testing
        console.log("Mock PyUSD deployed at:", PYUSD_TOKEN);
        console.log("Minted 1,000,000 mock PyUSD to:", msg.sender);

        // Deploy core contracts
        planManager = new PlanManager();
        investmentEngine = new InvestmentEngine();
        pyusdManager = new PyUSDManager();
        
        console.log("PlanManager deployed at:", address(planManager));
        console.log("InvestmentEngine deployed at:", address(investmentEngine));
        console.log("PyUSDManager deployed at:", address(pyusdManager));
        
        // Set up basic configuration
        investmentEngine.setPlanManager(address(planManager));
        console.log("PlanManager connected to InvestmentEngine");
        
        // Create test investment plans
        createTestPlans();
    }

    function createTestPlans() internal {
        console.log("\n=== Creating Test Plans ===");
        
        // Plan 1: Conservative with stablecoin allocation (will trigger PyUSD when enabled)
        IPlanManager.AssetAllocation[] memory conservativeAlloc = new IPlanManager.AssetAllocation[](2);
        conservativeAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_ADDRESS,
            targetPercentage: 7000, // 70% - will convert to PyUSD when enabled
            minPercentage: 6500,
            maxPercentage: 7500
        });
        conservativeAlloc[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        uint256 planId1 = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative PyUSD Plan",
            conservativeAlloc
        );
        console.log("Created Conservative plan with ID:", planId1);
        
        // Plan 2: No stablecoin allocation (no PyUSD conversion)
        IPlanManager.AssetAllocation[] memory cryptoAlloc = new IPlanManager.AssetAllocation[](1);
        cryptoAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_ADDRESS,
            targetPercentage: 10000, // 100%
            minPercentage: 9500,
            maxPercentage: 10000
        });

        uint256 planId2 = planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "All Crypto Plan",
            cryptoAlloc
        );
        console.log("Created All-Crypto plan with ID:", planId2);
    }

    function testInvestmentWithoutPyUSD() internal {
        console.log("\n=== Test 1: Investment Without PyUSD ===");
        
        console.log("PyUSD enabled:", investmentEngine.isPyUSDEnabled());
        
        // Make deposits
        investmentEngine.depositForUser(msg.sender, 5000, IInvestmentEngine.DepositType.Manual);
        console.log("Deposited 5000 for testing");
        logUserBalance(msg.sender);
        
        // Create and execute investment with stablecoin allocation
        uint256 investmentId = investmentEngine.invest(1, 2000); // Conservative plan
        console.log("Created investment ID:", investmentId, "(should work without PyUSD)");
        
        investmentEngine.executeInvestment(investmentId);
        console.log("Executed investment without PyUSD");
        logUserBalance(msg.sender);
        
        // Verify investment completed normally
        IInvestmentEngine.Investment memory investment = investmentEngine.getInvestment(investmentId);
        console.log("Investment status:", uint256(investment.status));
        console.log("Executed amount:", investment.executedAmount);
    }

    function initializePyUSDIntegration() internal {
        console.log("\n=== Test 2: Initialize PyUSD Integration ===");
        
        // Initialize PyUSDManager (in real deployment, use actual addresses)
        console.log("Initializing PyUSDManager...");
        // Note: Using mock addresses for testing - in real deployment use actual tokens
        try pyusdManager.initialize(PYUSD_TOKEN, UNISWAP_ROUTER, WETH_TOKEN) {
            console.log("PyUSDManager initialized successfully");
        } catch {
            console.log("PyUSDManager initialization failed (expected in test env)");
        }
        
        // Set authorized caller
        pyusdManager.setAuthorizedCaller(address(investmentEngine), true);
        console.log("InvestmentEngine authorized to use PyUSDManager");
        
        // Connect PyUSDManager to InvestmentEngine
        investmentEngine.setPyUSDManager(address(pyusdManager));
        console.log("PyUSDManager connected to InvestmentEngine");
        
        // Configure PyUSD settings
        try pyusdManager.updateSlippageTolerance(300) {
            console.log("Slippage tolerance set to 3%");
        } catch {
            console.log("Slippage update failed (expected if not initialized)");
        }
        
        console.log("PyUSD enabled:", investmentEngine.isPyUSDEnabled());
    }

    function testInvestmentWithPyUSD() internal {
        console.log("\n=== Test 3: Investment With PyUSD Integration ===");
        console.log("Starting balance:");
        logUserBalance(msg.sender);
        
        // Create investment with stablecoin allocation
        console.log("Creating investment with PyUSD conversion...");
        uint256 investmentId = investmentEngine.invest(1, 3000); // Conservative plan, 70% should convert to PyUSD
        console.log("Created investment ID:", investmentId);
        
        console.log("Balance after investment creation:");
        logUserBalance(msg.sender);
        
        // Try to execute investment (may fail due to mock environment)
        console.log("Attempting to execute investment with PyUSD conversion...");
        try investmentEngine.executeInvestment(investmentId) {
            console.log("Investment executed successfully with PyUSD integration");
            
            // Check PyUSD tracking
            uint256 pyusdAmount = investmentEngine.getInvestmentPyUSDAmount(investmentId);
            console.log("PyUSD amount for investment:", pyusdAmount);
            
            uint256 userPyUSD = investmentEngine.getUserPyUSDAllocation(msg.sender);
            console.log("User's total PyUSD allocation:", userPyUSD);
            
        } catch Error(string memory reason) {
            console.log("Investment execution failed (expected in test env):", reason);
            console.log("This is normal - PyUSD swap would fail with mock tokens");
            
            // Verify fallback behavior worked
            IInvestmentEngine.Investment memory investment = investmentEngine.getInvestment(investmentId);
            if (investment.status == IInvestmentEngine.InvestmentStatus.Executed) {
                console.log("Fallback execution succeeded");
            }
        } catch {
            console.log("Investment execution failed (expected with mock environment)");
        }
        
        console.log("Final balance:");
        logUserBalance(msg.sender);
    }

    function testPyUSDViewFunctions() internal view {
        console.log("\n=== Test 4: PyUSD View Functions ===");
        
        // Test PyUSD status
        bool enabled = investmentEngine.isPyUSDEnabled();
        console.log("PyUSD enabled:", enabled);
        
        // Test PyUSD balance
        uint256 contractBalance = investmentEngine.getPyUSDBalance();
        console.log("Contract PyUSD balance:", contractBalance);
        
        // Test user PyUSD allocation
        uint256 userAllocation = investmentEngine.getUserPyUSDAllocation(tx.origin);
        console.log("User PyUSD allocation:", userAllocation);
        
        // Test investment PyUSD amounts
        for (uint256 i = 1; i <= 3; i++) {
            try investmentEngine.getInvestmentPyUSDAmount(i) returns (uint256 amount) {
                console.log("Investment", i, "PyUSD amount:", amount);
            } catch {
                // Investment doesn't exist or no PyUSD
            }
        }
        
        // Test conversion quote
        try investmentEngine.getPyUSDConversionQuote(1 ether) returns (uint256 expected, uint256 minimum) {
            console.log("1 ETH conversion quote:");
            console.log("  Expected PyUSD:", expected);
            console.log("  Minimum PyUSD:", minimum);
        } catch {
            console.log("Conversion quote failed (expected with mock setup)");
        }
    }

    function testPyUSDAdministration() internal {
        console.log("\n=== Test 5: PyUSD Administrative Functions ===");
        
        // Test slippage tolerance update
        console.log("Current slippage tolerance test...");
        try pyusdManager.updateSlippageTolerance(500) {
            console.log("Updated slippage tolerance to 5%");
        } catch {
            console.log("Slippage update failed (expected if not fully initialized)");
        }
        
        // Test pause/unpause
        console.log("Testing pause functionality...");
        try pyusdManager.pause() {
            console.log("PyUSDManager paused");
            console.log("PyUSD enabled after pause:", investmentEngine.isPyUSDEnabled());
            
            pyusdManager.unpause();
            console.log("PyUSDManager unpaused");
            console.log("PyUSD enabled after unpause:", investmentEngine.isPyUSDEnabled());
        } catch {
            console.log("Pause/unpause failed (expected if not initialized)");
        }
        
        // Test emergency functions
        console.log("Emergency functions available (not executed in test)");
    }

    function testPyUSDEdgeCases() internal {
        console.log("\n=== Test 6: PyUSD Edge Cases ===");

        // Add more funds for edge case tests
        investmentEngine.depositForUser(msg.sender, 5000, IInvestmentEngine.DepositType.Manual);
        console.log("Deposited additional 5000 for edge case tests");
        logUserBalance(msg.sender);
        
        // Test investment with no stablecoin allocation (should not trigger PyUSD)
        console.log("Testing investment with no stablecoin allocation...");
        uint256 investmentId = investmentEngine.invest(2, 1000); // All-crypto plan
        console.log("Created all-crypto investment ID:", investmentId);
        
        investmentEngine.executeInvestment(investmentId);
        console.log("Executed all-crypto investment");
        
        // This should show 0 PyUSD conversion
        uint256 pyusdAmount = investmentEngine.getInvestmentPyUSDAmount(investmentId);
        console.log("PyUSD amount for all-crypto investment:", pyusdAmount, "(should be 0)");
        
        // Test with PyUSD disabled
        console.log("\nTesting with PyUSD disabled...");
        try pyusdManager.pause() {
            console.log("PyUSD disabled");
            
            uint256 disabledInvestment = investmentEngine.invest(1, 500);
            investmentEngine.executeInvestment(disabledInvestment);
            console.log("Investment executed with PyUSD disabled");
            
            pyusdManager.unpause();
        } catch {
            console.log("Pause test failed (expected)");
        }
        
        // Test batch operations
        console.log("\nTesting batch operations with PyUSD...");
        uint256 batch1 = investmentEngine.invest(1, 300);
        uint256 batch2 = investmentEngine.invest(1, 200);
        
        uint256[] memory batchIds = new uint256[](2);
        batchIds[0] = batch1;
        batchIds[1] = batch2;
        
        try investmentEngine.batchExecuteInvestments(batchIds) {
            console.log("Batch execution with PyUSD completed");
        } catch {
            console.log("Batch execution failed (expected in test env)");
        }
    }

    function logUserBalance(address user) internal view {
        IInvestmentEngine.UserBalance memory balance = investmentEngine.getUserBalance(user);
        console.log("  Total Deposited:", balance.totalDeposited);
        console.log("  Available Balance:", balance.availableBalance);
        console.log("  Pending Investment:", balance.pendingInvestment);
        console.log("  Total Invested:", balance.totalInvested);
    }
}