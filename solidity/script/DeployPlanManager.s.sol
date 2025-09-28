// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PlanManager} from "../src/PlanManager.sol";
import {IPlanManager} from "../src/interfaces/IPlanManager.sol";

contract DeployPlanManagerScript is Script {
    PlanManager public planManager;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy PlanManager
        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));
        console.log("Owner:", planManager.owner());

        // Display initial asset risk factors
        console.log("\n=== Initial Asset Risk Factors ===");
        console.log("Stablecoin Risk:", planManager.assetRiskFactors(IPlanManager.AssetClass.Stablecoin));
        console.log("RWA Risk:", planManager.assetRiskFactors(IPlanManager.AssetClass.RWA));
        console.log("Crypto Risk:", planManager.assetRiskFactors(IPlanManager.AssetClass.Crypto));
        console.log("Liquidity Risk:", planManager.assetRiskFactors(IPlanManager.AssetClass.Liquidity));

        console.log("\n=== Initial State ===");
        console.log("Total Plans:", planManager.getTotalPlans());

        vm.stopBroadcast();
    }
}