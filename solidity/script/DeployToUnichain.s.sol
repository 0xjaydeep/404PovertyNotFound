// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InvestmentEngine} from "../src/InvestmentEngine.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";

/**
 * Deployment script for Unichain networks (mainnet and testnet)
 * Includes comprehensive setup and initial configuration
 */
contract DeployToUnichainScript is Script {
    PlanManager public planManager;
    InvestmentEngine public investmentEngine;

    // Unichain token addresses (update these with actual addresses)
    address constant UNICHAIN_USDC = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1; // Update with real USDC on Unichain
    address constant UNICHAIN_WETH = 0x4200000000000000000000000000000000000006; // Update with real WETH on Unichain
    address constant UNICHAIN_WBTC = 0x68f180fcCe6836688e9084f035309E29Bf0A2095; // Update with real WBTC on Unichain

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deploying to Unichain ===");
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy contracts
        deployContracts();

        // Setup initial configuration
        setupInitialConfiguration();

        // Create default investment plans
        createDefaultPlans();

        // Display deployment summary
        displayDeploymentSummary();

        vm.stopBroadcast();
    }

    function deployContracts() internal {
        console.log("\n=== Contract Deployment ===");

        // Deploy PlanManager
        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));

        // Deploy InvestmentEngine
        investmentEngine = new InvestmentEngine();
        console.log("InvestmentEngine deployed at:", address(investmentEngine));

        // Link contracts
        investmentEngine.setPlanManager(address(planManager));
        console.log("Contracts linked successfully");
    }

    function setupInitialConfiguration() internal {
        console.log("\n=== Initial Configuration ===");

        // Set minimum deposit (0.01 USDC equivalent)
        uint256 minimumDeposit = 10000; // 0.01 USDC (6 decimals)
        investmentEngine.setMinimumDeposit(minimumDeposit);
        console.log("Minimum deposit set to:", minimumDeposit);

        // Display initial asset risk factors
        console.log("\nAsset Risk Factors:");
        console.log("- Stablecoin:", planManager.assetRiskFactors(IPlanManager.AssetClass.Stablecoin));
        console.log("- RWA:", planManager.assetRiskFactors(IPlanManager.AssetClass.RWA));
        console.log("- Liquidity:", planManager.assetRiskFactors(IPlanManager.AssetClass.Liquidity));
        console.log("- Crypto:", planManager.assetRiskFactors(IPlanManager.AssetClass.Crypto));
    }

    function createDefaultPlans() internal {
        console.log("\n=== Creating Default Investment Plans ===");

        // Conservative Plan (70% Stablecoin, 30% RWA)
        createConservativePlan();

        // Balanced Plan (40% Stablecoin, 30% RWA, 30% Crypto)
        createBalancedPlan();

        // Aggressive Plan (20% Stablecoin, 30% RWA, 50% Crypto)
        createAggressivePlan();

        // DeFi Plan (20% Stablecoin, 40% Liquidity, 40% Crypto)
        createDeFiPlan();
    }

    function createConservativePlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](2);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: UNICHAIN_USDC,
            targetPercentage: 7000, // 70%
            minPercentage: 6500,
            maxPercentage: 7500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: UNICHAIN_USDC, // Placeholder for RWA token
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Conservative,
            "Conservative Growth",
            allocations
        );

        console.log("Conservative Plan created - ID:", planId, "Risk Score:", calculateAndDisplayRisk(allocations));
    }

    function createBalancedPlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: UNICHAIN_USDC,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,
            maxPercentage: 4500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: UNICHAIN_USDC, // Placeholder for RWA token
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: UNICHAIN_WETH,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Balanced Portfolio",
            allocations
        );

        console.log("Balanced Plan created - ID:", planId, "Risk Score:", calculateAndDisplayRisk(allocations));
    }

    function createAggressivePlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: UNICHAIN_USDC,
            targetPercentage: 2000, // 20%
            minPercentage: 1500,
            maxPercentage: 2500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.RWA,
            tokenAddress: UNICHAIN_USDC, // Placeholder for RWA token
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: UNICHAIN_WETH,
            targetPercentage: 5000, // 50%
            minPercentage: 4500,
            maxPercentage: 5500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "Aggressive Growth",
            allocations
        );

        console.log("Aggressive Plan created - ID:", planId, "Risk Score:", calculateAndDisplayRisk(allocations));
    }

    function createDeFiPlan() internal {
        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](3);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: UNICHAIN_USDC,
            targetPercentage: 2000, // 20%
            minPercentage: 1500,
            maxPercentage: 2500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Liquidity,
            tokenAddress: UNICHAIN_WETH, // Placeholder for LP token
            targetPercentage: 4000, // 40%
            minPercentage: 3500,
            maxPercentage: 4500
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: UNICHAIN_WBTC,
            targetPercentage: 4000, // 40%
            minPercentage: 3500,
            maxPercentage: 4500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Custom,
            "DeFi Focused",
            allocations
        );

        console.log("DeFi Plan created - ID:", planId, "Risk Score:", calculateAndDisplayRisk(allocations));
    }

    function calculateAndDisplayRisk(IPlanManager.AssetAllocation[] memory allocations) internal view returns (uint256) {
        return planManager.calculateRiskScore(allocations);
    }

    function displayDeploymentSummary() internal view {
        console.log("\n=== Deployment Summary ===");
        console.log("Network: Unichain (Chain ID:", block.chainid, ")");
        console.log("PlanManager:", address(planManager));
        console.log("InvestmentEngine:", address(investmentEngine));
        console.log("Owner:", investmentEngine.owner());
        console.log("Total Plans:", planManager.getTotalPlans());
        console.log("Minimum Deposit:", investmentEngine.minimumDeposit());

        console.log("\n=== Contract Verification Commands ===");
        console.log("Verify PlanManager:");
        console.log("forge verify-contract", address(planManager), "src/PlanManager.sol:PlanManager --chain-id", block.chainid);
        console.log("Verify InvestmentEngine:");
        console.log("forge verify-contract", address(investmentEngine), "src/InvestmentEngine.sol:InvestmentEngine --chain-id", block.chainid);

        console.log("\n=== Next Steps ===");
        console.log("1. Verify contracts on block explorer");
        console.log("2. Update frontend with contract addresses");
        console.log("3. Update token addresses with real Unichain tokens");
        console.log("4. Test deposit and investment functionality");
        console.log("5. Set up monitoring and alerts");

        console.log("\n=== Important Addresses ===");
        console.log("Save these addresses for frontend integration:");
        console.log("PLAN_MANAGER_ADDRESS =", address(planManager));
        console.log("INVESTMENT_ENGINE_ADDRESS =", address(investmentEngine));
    }
}