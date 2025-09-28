// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InvestmentEngineV3Simple} from "../src/InvestmentEngineV3.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {MockERC20} from "../src/tokens/MockERC20.sol";
import {MockUniswapV4Router} from "../src/mocks/MockUniswapV4Router.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";

/**
 * @title DeployInvestmentEngineV3Script
 * @dev Deployment script for InvestmentEngineV3 with Uniswap V4 integration
 * Includes mock router for testing and demo purposes
 */
contract DeployInvestmentEngineV3Script is Script {
    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/

    InvestmentEngineV3Simple public investmentEngine;
    PlanManager public planManager;
    MockUniswapV4Router public mockRouter; // For demo purposes

    /*//////////////////////////////////////////////////////////////
                               TOKENS
    //////////////////////////////////////////////////////////////*/

    MockERC20 public usdc;
    MockERC20 public wbtc;
    MockERC20 public weth;
    MockERC20 public link;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 constant INITIAL_LIQUIDITY = 1000000 * 10**6; // 1M USDC
    uint256 constant DEMO_AMOUNT = 10000 * 10**6;         // 10K USDC

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        console.log("==========================================");
        console.log("DEPLOYING INVESTMENT ENGINE V3");
        console.log("==========================================");

        deployTokens();
        deployCore();
        configureSystem();
        createDemoPlans();
        demonstrateInvestment();

        console.log("==========================================");
        console.log("DEPLOYMENT COMPLETED SUCCESSFULLY!");
        console.log("==========================================");

        vm.stopBroadcast();
    }

    function deployTokens() internal {
        console.log("Deploying tokens...");

        // Deploy mock tokens for demo
        usdc = new MockERC20("USD Coin", "USDC", 6, 100000000 * 10**6, 100000 * 10**6);
        wbtc = new MockERC20("Wrapped Bitcoin", "WBTC", 8, 10000 * 10**8, 100 * 10**6);
        weth = new MockERC20("Wrapped Ether", "WETH", 18, 1000000 * 10**18, 10000 * 10**18);
        link = new MockERC20("Chainlink", "LINK", 18, 10000000 * 10**18, 100000 * 10**18);

        console.log("USDC deployed at:", address(usdc));
        console.log("WBTC deployed at:", address(wbtc));
        console.log("WETH deployed at:", address(weth));
        console.log("LINK deployed at:", address(link));
    }

    function deployCore() internal {
        console.log("Deploying core contracts...");

        // Deploy PlanManager
        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));

        // Deploy Mock Uniswap V4 Router
        mockRouter = new MockUniswapV4Router();
        console.log("Mock V4 Router deployed at:", address(mockRouter));

        // Deploy InvestmentEngineV3
        investmentEngine = new InvestmentEngineV3Simple(
            address(planManager),
            address(mockRouter),
            address(usdc),
            address(0) // Mock Pyth address - replace with actual Pyth address on mainnet
        );
        console.log("InvestmentEngineV3 deployed at:", address(investmentEngine));
        console.log("Note: Entropy feature is disabled by default. Use setEntropy() to enable.");
    }

    function configureSystem() internal {
        console.log("Configuring system...");

        // Fund mock router with liquidity
        usdc.mint(address(mockRouter), INITIAL_LIQUIDITY);
        wbtc.mint(address(mockRouter), 100 * 10**8);      // 100 WBTC
        weth.mint(address(mockRouter), 10000 * 10**18);   // 10K WETH
        link.mint(address(mockRouter), 1000000 * 10**18); // 1M LINK

        // Set exchange rates for demo
        mockRouter.setExchangeRate(address(usdc), address(usdc), 1e18);      // 1:1
        mockRouter.setExchangeRate(address(usdc), address(wbtc), 2e13);      // ~$50k BTC
        mockRouter.setExchangeRate(address(usdc), address(weth), 3e17);      // ~$3.33 ETH
        mockRouter.setExchangeRate(address(usdc), address(link), 5e16);      // ~$20 LINK

        console.log("System configured with liquidity and exchange rates");
    }

    function createDemoPlans() internal {
        console.log("Creating demo investment plans...");

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

        uint256 conservativePlanId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative DeFi Portfolio",
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

        uint256 balancedPlanId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Balanced Growth Portfolio",
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

        uint256 aggressivePlanId = planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "Aggressive Growth Strategy",
            aggressiveAllocations
        );

        console.log("Demo plans created:");
        console.log("Conservative Plan ID:", conservativePlanId);
        console.log("Balanced Plan ID:", balancedPlanId);
        console.log("Aggressive Plan ID:", aggressivePlanId);
    }

    function demonstrateInvestment() internal {
        console.log("Demonstrating investment functionality...");

        // Create demo user
        address demoUser = vm.addr(1);

        // Fund demo user
        usdc.mint(demoUser, DEMO_AMOUNT * 3);
        console.log("Demo user funded with:", DEMO_AMOUNT * 3 / 10**6, "USDC");

        // Demonstrate conservative investment
        vm.startPrank(demoUser);

        usdc.approve(address(investmentEngine), DEMO_AMOUNT);
        uint256 investmentId = investmentEngine.depositAndInvest(DEMO_AMOUNT, 1);

        vm.stopPrank();

        // Show results
        InvestmentEngineV3Simple.Investment memory investment = investmentEngine.getInvestment(investmentId);
        console.log("Demo investment created:");
        console.log("Investment ID:", investmentId);
        console.log("User:", investment.user);
        console.log("Plan ID:", investment.planId);
        console.log("Amount:", investment.amount / 10**6, "USDC");

        // Show token balances
        console.log("Demo user token balances after investment:");
        console.log("USDC:", usdc.balanceOf(demoUser) / 10**6);
        console.log("WETH:", weth.balanceOf(demoUser) / 10**18);
    }

    /*//////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getDeploymentSummary() external view returns (
        address _investmentEngine,
        address _planManager,
        address _router,
        address _usdc,
        uint256 _totalPlans,
        uint256 _totalInvestments
    ) {
        return (
            address(investmentEngine),
            address(planManager),
            address(mockRouter),
            address(usdc),
            planManager.getTotalPlans(),
            investmentEngine.getTotalInvestments()
        );
    }

    function getDemoTokenAddresses() external view returns (
        address _usdc,
        address _wbtc,
        address _weth,
        address _link
    ) {
        return (
            address(usdc),
            address(wbtc),
            address(weth),
            address(link)
        );
    }
}