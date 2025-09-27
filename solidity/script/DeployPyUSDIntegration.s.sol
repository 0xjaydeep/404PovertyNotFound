// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InvestmentEngine} from "../src/InvestmentEngine.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {PyUSDManager} from "../src/investments/PyUSDManager.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";

/**
 * Deployment script for complete PyUSD integration
 * Deploys all contracts and sets up PyUSD functionality
 */
contract DeployPyUSDIntegrationScript is Script {
    // Contract instances
    InvestmentEngine public investmentEngine;
    PlanManager public planManager;
    PyUSDManager public pyusdManager;

    // Mainnet addresses (for production)
    address constant PYUSD_MAINNET = 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8;
    address constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // Mock addresses (for testing)
    address constant USDC_MOCK = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1;
    address constant WETH_MOCK = 0x4200000000000000000000000000000000000006;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        console.log("=== Deploying PyUSD Integration ===");
        
        // Step 1: Deploy all contracts
        deployAllContracts();
        
        // Step 2: Initialize PyUSD (will fail in test env - that's expected)
        initializePyUSDSystem();
        
        // Step 3: Create PyUSD-compatible investment plans
        createPyUSDPlans();
        
        // Step 4: Verify integration
        verifyIntegration();
        
        // Step 5: Display deployment summary
        displayDeploymentSummary();

        vm.stopBroadcast();
    }

    function deployAllContracts() internal {
        console.log("\n--- Step 1: Deploying Contracts ---");
        
        // Deploy PlanManager
        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));
        
        // Deploy InvestmentEngine
        investmentEngine = new InvestmentEngine();
        console.log("InvestmentEngine deployed at:", address(investmentEngine));
        
        // Deploy PyUSDManager
        pyusdManager = new PyUSDManager();
        console.log("PyUSDManager deployed at:", address(pyusdManager));
        
        // Connect PlanManager to InvestmentEngine
        investmentEngine.setPlanManager(address(planManager));
        console.log("PlanManager connected to InvestmentEngine");
    }

    function initializePyUSDSystem() internal {
        console.log("\n--- Step 2: Initializing PyUSD System ---");
        
        // Try to initialize PyUSDManager with mainnet addresses
        console.log("Attempting to initialize PyUSDManager...");
        try pyusdManager.initialize(PYUSD_MAINNET, UNISWAP_V3_ROUTER, WETH_MAINNET) {
            console.log("PyUSDManager initialized successfully");
            
            // Set authorized caller
            pyusdManager.setAuthorizedCaller(address(investmentEngine), true);
            console.log("InvestmentEngine authorized to use PyUSDManager");
            
            // Connect PyUSDManager to InvestmentEngine
            investmentEngine.setPyUSDManager(address(pyusdManager));
            console.log("PyUSDManager connected to InvestmentEngine");
            
            // Configure default settings
            pyusdManager.updateSlippageTolerance(300); // 3%
            console.log("Slippage tolerance set to 3%");
            
        } catch Error(string memory reason) {
            console.log("PyUSDManager initialization failed:", reason);
            console.log("This is expected in test environment");
            
            // Still connect for testing, but PyUSD won't be active
            investmentEngine.setPyUSDManager(address(pyusdManager));
            console.log("PyUSDManager connected (inactive)");
            
        } catch {
            console.log("PyUSDManager initialization failed (unknown error)");
            console.log("Connecting inactive PyUSDManager for testing");
            investmentEngine.setPyUSDManager(address(pyusdManager));
        }
    }

    function createPyUSDPlans() internal {
        console.log("\n--- Step 3: Creating PyUSD-Compatible Plans ---");
        
        // Plan 1: Conservative with 50% PyUSD allocation
        IPlanManager.AssetAllocation[] memory conservativeAlloc = new IPlanManager.AssetAllocation[](2);
        conservativeAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_MOCK,
            targetPercentage: 5000, // 50% → PyUSD
            minPercentage: 4500,
            maxPercentage: 5500
        });
        conservativeAlloc[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_MOCK,
            targetPercentage: 5000, // 50%
            minPercentage: 4500,
            maxPercentage: 5500
        });

        uint256 conservativePlanId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative PyUSD Plan",
            conservativeAlloc
        );
        console.log("Conservative PyUSD Plan created with ID:", conservativePlanId);
        
        // Plan 2: Balanced with 30% PyUSD allocation
        IPlanManager.AssetAllocation[] memory balancedAlloc = new IPlanManager.AssetAllocation[](3);
        balancedAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: USDC_MOCK,
            targetPercentage: 3000, // 30% → PyUSD
            minPercentage: 2500,
            maxPercentage: 3500
        });
        balancedAlloc[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_MOCK,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,
            maxPercentage: 4500
        });
        balancedAlloc[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: 0x1234567890123456789012345678901234567890,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        uint256 balancedPlanId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Balanced PyUSD Plan",
            balancedAlloc
        );
        console.log("Balanced PyUSD Plan created with ID:", balancedPlanId);
        
        // Plan 3: No stablecoin allocation (no PyUSD conversion)
        IPlanManager.AssetAllocation[] memory noPyUSDAlloc = new IPlanManager.AssetAllocation[](1);
        noPyUSDAlloc[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: WETH_MOCK,
            targetPercentage: 10000, // 100%
            minPercentage: 9500,
            maxPercentage: 10000
        });

        uint256 noPyUSDPlanId = planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "All Crypto (No PyUSD)",
            noPyUSDAlloc
        );
        console.log("No PyUSD Plan created with ID:", noPyUSDPlanId);
    }

    function verifyIntegration() internal view {
        console.log("\n--- Step 4: Verifying Integration ---");
        
        // Check PyUSD status
        bool pyusdEnabled = investmentEngine.isPyUSDEnabled();
        console.log("PyUSD integration enabled:", pyusdEnabled);
        
        // Check contract connections
        address connectedPlanManager = investmentEngine.planManager();
        console.log("PlanManager connected:", connectedPlanManager == address(planManager));
        
        // Check total plans created
        uint256 totalPlans = planManager.getTotalPlans();
        console.log("Total investment plans created:", totalPlans);
        
        // Verify PyUSD Manager initialization status
        try pyusdManager.isInitialized() returns (bool initialized) {
            console.log("PyUSDManager initialized:", initialized);
        } catch {
            console.log("PyUSDManager not initialized (expected in test)");
        }
        
        // Check authorized caller
        bool authorized = pyusdManager.authorizedCallers(address(investmentEngine));
        console.log("InvestmentEngine authorized:", authorized);
        
        console.log("Integration verification completed");
    }

    function displayDeploymentSummary() internal view {
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("PlanManager:      ", address(planManager));
        console.log("InvestmentEngine: ", address(investmentEngine));
        console.log("PyUSDManager:     ", address(pyusdManager));
        
        console.log("\n=== CONFIGURATION ===");
        console.log("Owner:            ", investmentEngine.owner());
        console.log("Minimum Deposit:  ", investmentEngine.minimumDeposit());
        console.log("PyUSD Enabled:    ", investmentEngine.isPyUSDEnabled());
        console.log("Total Plans:      ", planManager.getTotalPlans());
        
        console.log("\n=== NEXT STEPS ===");
        console.log("1. Fund contract with ETH for PyUSD conversions");
        console.log("2. Test investment creation and execution");
        console.log("3. Monitor PyUSD conversion events");
        console.log("4. Configure slippage tolerance as needed");
        
        if (!investmentEngine.isPyUSDEnabled()) {
            console.log("\n <|  PyUSD NOT ACTIVE - Expected in test environment");
            console.log("   For mainnet: Ensure proper token addresses and sufficient liquidity");
        }
    }
}