// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/PlanManager.sol";
import "../src/InvestmentEngineV3.sol";
import "../src/tokens/MockERC20.sol";
import "../src/interfaces/IPlanManager.sol";

contract DeployToSepolia is Script {
    // Sepolia Addresses
    address constant UNISWAP_V3_ROUTER_SEPOLIA =
        0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;
    address constant PYTH_ORACLE_SEPOLIA =
        0xDd24F84d36BF92C65F92307595335bdFab5Bbd21;
    address constant PYUSD_SEPOLIA = 0xd69ff8b558859EcE74CB7b5c8196463AaC259E14;

    function run() public {
        vm.startBroadcast();

        // Deploy Mock Tokens
        MockERC20 usdc = new MockERC20(
            "USD Coin",
            "USDC",
            6,
            1000000 * 10 ** 6,
            1000 * 10 ** 6
        );
        MockERC20 weth = new MockERC20(
            "Wrapped Ether",
            "WETH",
            18,
            1000 * 10 ** 18,
            1 * 10 ** 18
        );
        MockERC20 link = new MockERC20(
            "ChainLink",
            "LINK",
            18,
            10000 * 10 ** 18,
            100 * 10 ** 18
        );

        // Deploy Core Contracts
        PlanManager planManager = new PlanManager();
        InvestmentEngineV3Simple investmentEngineV3 = new InvestmentEngineV3Simple(
            address(planManager),
            UNISWAP_V3_ROUTER_SEPOLIA,
            PYUSD_SEPOLIA, // Using PYUSD as the base token
            PYTH_ORACLE_SEPOLIA
        );

        // Set initial price feeds for mock tokens
        address[] memory tokens = new address[](2);
        tokens[0] = address(weth);
        tokens[1] = address(link);

        bytes32[] memory ids = new bytes32[](2);
        ids[
            0
        ] = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace; // WETH/USD
        ids[
            1
        ] = 0x8ac0c70fff57e9aefdf5edf44b51d62c2d433653cbb2cf5cc06bb115af04d221; // LINK/USD

        investmentEngineV3.setInitialPriceFeeds(tokens, ids);

        // Create a demo plan with the deployed mock tokens
        createDemoPlan(planManager, address(weth), address(link));

        vm.stopBroadcast();

        console.log("\n=== DEPLOYMENT TO SEPOLIA COMPLETE ===");
        console.log("PlanManager Address:", address(planManager));
        console.log("InvestmentEngineV3 Address:", address(investmentEngineV3));
        console.log("PYUSD (Base Token) Address:", PYUSD_SEPOLIA);
        console.log("MockWETH Address:", address(weth));
        console.log("MockLINK Address:", address(link));
    }

    function createDemoPlan(
        PlanManager planManager,
        address weth,
        address link
    ) internal {
        IPlanManager.AssetAllocation[]
            memory allocations = new IPlanManager.AssetAllocation[](2);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: weth,
            targetPercentage: 7000, // 70%
            minPercentage: 6500,
            maxPercentage: 7500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: link,
            targetPercentage: 3000, // 30%
            minPercentage: 2500,
            maxPercentage: 3500
        });

        planManager.createPlan(
            IPlanManager.PlanType.Aggressive,
            "Sepolia Aggressive Portfolio",
            allocations
        );
    }
}
