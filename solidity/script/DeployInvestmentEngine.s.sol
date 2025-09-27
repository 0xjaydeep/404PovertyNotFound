// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InvestmentEngine} from "../src/InvestmentEngine.sol";
import {PlanManager} from "../src/PlanManager.sol";

contract DeployInvestmentEngineScript is Script {
    InvestmentEngine public investmentEngine;
    PlanManager public planManager;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy PlanManager first (required dependency)
        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));

        // Deploy InvestmentEngine
        investmentEngine = new InvestmentEngine();
        console.log("InvestmentEngine deployed at:", address(investmentEngine));

        // Configure InvestmentEngine
        investmentEngine.setPlanManager(address(planManager));
        console.log("PlanManager set in InvestmentEngine");

        // Display initial configuration
        console.log("\n=== InvestmentEngine Configuration ===");
        console.log("Owner:", investmentEngine.owner());
        console.log("Plan Manager:", investmentEngine.planManager());
        console.log("Minimum Deposit:", investmentEngine.minimumDeposit());

        // Test administrative functions
        console.log("\n=== Testing Administrative Functions ===");

        // Update minimum deposit
        uint256 newMinDeposit = 500;
        investmentEngine.setMinimumDeposit(newMinDeposit);
        console.log("Updated minimum deposit to:", newMinDeposit);
        console.log("Current minimum deposit:", investmentEngine.minimumDeposit());

        // Display PlanManager configuration
        console.log("\n=== PlanManager Configuration ===");
        console.log("Total plans in PlanManager:", planManager.getTotalPlans());
        console.log("PlanManager owner:", planManager.owner());

        vm.stopBroadcast();
    }
}