// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/PlanManager.sol";
import "../src/InvestmentEngineV3.sol";
import "../src/tokens/MockERC20.sol";
import "../src/mocks/MockUniswapV4Router.sol";
import "../src/interfaces/IPlanManager.sol";

/**
 * @title DeployV3
 * @dev Deploys the V3 contracts for the 404PovertyNotFound platform.
 */
contract DeployV3 is Script {
    PlanManager public planManager;
    InvestmentEngineV3Simple public investmentEngineV3;
    MockUniswapV4Router public router;
    MockERC20 public usdc;
    MockERC20 public weth;
    MockERC20 public wbtc;
    MockERC20 public link;

    function run() public {
        vm.startBroadcast();

        console.log("=== DEPLOYING V3 CONTRACTS ===");

        // 1. Deploy Mock Tokens
        usdc = new MockERC20("USD Coin", "USDC", 6, 1000000 * 10 ** 6, 1000 * 10 ** 6);
        weth = new MockERC20("Wrapped Ether", "WETH", 18, 1000 * 10 ** 18, 1 * 10 ** 18);
        wbtc = new MockERC20("Wrapped Bitcoin", "WBTC", 8, 100 * 10 ** 8, 1 * 10 ** 6);
        link = new MockERC20("ChainLink", "LINK", 18, 10000 * 10 ** 18, 100 * 10 ** 18);

        // 2. Deploy Core Contracts
        planManager = new PlanManager();
        router = new MockUniswapV4Router();
        investmentEngineV3 = new InvestmentEngineV3Simple(address(planManager), address(router), address(usdc), address(0));

        // 3. Create a demo plan
        createDemoPlan();

        vm.stopBroadcast();

        console.log("\n=== V3 DEPLOYMENT COMPLETE ===");
        console.log("Copy these addresses into your .env file:\n");
        console.log("LOCAL_PLAN_MANAGER_ADDRESS=", address(planManager));
        console.log("LOCAL_INVESTMENT_ENGINE_V3_ADDRESS=", address(investmentEngineV3));
        console.log("LOCAL_UNISWAP_V4_ROUTER_ADDRESS=", address(router));
        console.log("LOCAL_USDC_ADDRESS=", address(usdc));
        console.log("LOCAL_WETH_ADDRESS=", address(weth));
        console.log("LOCAL_WBTC_ADDRESS=", address(wbtc));
        console.log("LOCAL_LINK_ADDRESS=", address(link));
    }

    function createDemoPlan() internal {
        console.log("\n=== CREATING DEMO PLAN ===");

        IPlanManager.AssetAllocation[]
            memory allocations = new IPlanManager.AssetAllocation[](3);

        // 60% WETH, 30% WBTC, 10% LINK
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(weth),
            targetPercentage: 6000, // 60%
            minPercentage: 5500,
            maxPercentage: 6500
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
            targetPercentage: 1000, // 10%
            minPercentage: 500,
            maxPercentage: 1500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "V3 Aggressive Crypto Portfolio",
            allocations
        );

        console.log("Demo plan created with ID:", planId);
    }
}
