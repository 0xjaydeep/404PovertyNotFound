// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/PlanManager.sol";
import "../src/InvestmentEngineV2.sol";
import "../src/tokens/MockERC20.sol";
import "../src/interfaces/IPlanManager.sol";

/**
 * @title HackathonDemo
 * @dev Quick demo script showcasing all 404PovertyNotFound features
 */
contract HackathonDemo is Script {
    PlanManager public planManager;
    InvestmentEngineV2 public investmentEngine;
    MockERC20 public usdc;
    MockERC20 public wbtc;
    MockERC20 public weth;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function run() public {
        vm.startBroadcast();

        console.log("=== 404 POVERTY NOT FOUND - HACKATHON DEMO ===");
        console.log("===============================================");

        // 1. Deploy everything
        setupContracts();

        // 2. Create investment plans
        uint256 planId = createDemoPlan();

        // 3. Show user journey
        // demonstrateUserJourney(planId);

        // 4. Show portfolio results
        // showPortfolioResults();

        vm.stopBroadcast();

        console.log("\n=== DEMO COMPLETE! ===");
        console.log("Features showcased:");
        console.log("- Automated salary-based crypto investing");
        console.log("- Multi-token portfolio allocation");
        console.log("- Real-time balance tracking");
        console.log("- ERC20 token integration");
    }

    function setupContracts() internal {
        console.log("\n=== DEPLOYING CONTRACTS ===");
        console.log("============================");

        // Deploy tokens
        usdc = new MockERC20(
            "USD Coin",
            "USDC",
            6,
            1000000 * 10 ** 6,
            1000 * 10 ** 6
        );
        wbtc = new MockERC20(
            "Wrapped Bitcoin",
            "WBTC",
            8,
            100 * 10 ** 8,
            1 * 10 ** 6
        );
        weth = new MockERC20(
            "Wrapped Ether",
            "WETH",
            18,
            1000 * 10 ** 18,
            1 * 10 ** 18
        );

        console.log("Tokens deployed:");
        console.log("   USDC:", address(usdc));
        console.log("   WBTC:", address(wbtc));
        console.log("   WETH:", address(weth));

        // Deploy core contracts
        planManager = new PlanManager();
        investmentEngine = new InvestmentEngineV2(address(usdc));
        investmentEngine.setPlanManager(address(planManager));

        console.log("Core contracts:");
        console.log("   PlanManager:", address(planManager));
        console.log("   InvestmentEngine:", address(investmentEngine));

        // Fund contract with tokens for simulated trading
        usdc.transfer(address(investmentEngine), 100000 * 10 ** 6);
        wbtc.transfer(address(investmentEngine), 10 * 10 ** 8);
        weth.transfer(address(investmentEngine), 100 * 10 ** 18);

        console.log("Contract funded with tokens for trading");
    }

    function createDemoPlan() internal returns (uint256) {
        console.log("\n CREATING INVESTMENT PLAN");
        console.log("============================");

        IPlanManager.AssetAllocation[]
            memory allocations = new IPlanManager.AssetAllocation[](3);

        // 50% WETH, 30% WBTC, 20% USDC (stable)
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(weth),
            targetPercentage: 5000, // 50%
            minPercentage: 4500,
            maxPercentage: 5500
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
            targetPercentage: 2000, // 20%
            minPercentage: 1500,
            maxPercentage: 2500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Hackathon Crypto Portfolio",
            allocations
        );

        console.log(" Plan created with ID:", planId);
        console.log(" Allocation: 50% WETH, 30% WBTC, 20% USDC");

        return planId;
    }

    // function demonstrateUserJourney(uint256 planId) internal {
    //     console.log("\n USER JOURNEY SIMULATION");
    //     console.log("===========================");

    //     vm.stopBroadcast();

    //     // Alice receives salary and invests
    //     console.log("Alice receives $2000 salary");

    //     vm.broadcast();
    //     usdc.mint(alice, 2000 * 10 ** 6);

    //     vm.broadcast(alice);
    //     usdc.approve(address(investmentEngine), 2000 * 10 ** 6);

    //     vm.broadcast(alice);
    //     investmentEngine.depositToken(
    //         address(usdc),
    //         2000 * 10 ** 6,
    //         IInvestmentEngine.DepositType.Salary
    //     );

    //     console.log("Alice deposited $2000 USDC");

    //     // Alice invests $1500 in the plan
    //     vm.broadcast(alice);
    //     uint256 investmentId = investmentEngine.invest(planId, 1500 * 10 ** 6);

    //     console.log("Alice created investment of $1500");

    //     // Execute investment (automated portfolio allocation)
    //     vm.broadcast();
    //     investmentEngine.executeInvestment(investmentId);

    //     console.log("Investment executed - tokens allocated automatically!");

    //     // Bob also invests
    //     console.log("\nBob receives $1000 salary");

    //     vm.broadcast();
    //     usdc.mint(bob, 1000 * 10 ** 6);

    //     vm.broadcast(bob);
    //     usdc.approve(address(investmentEngine), 1000 * 10 ** 6);

    //     vm.broadcast(bob);
    //     investmentEngine.depositToken(
    //         address(usdc),
    //         1000 * 10 ** 6,
    //         IInvestmentEngine.DepositType.Salary
    //     );

    //     vm.broadcast(bob);
    //     uint256 bobInvestmentId = investmentEngine.invest(
    //         planId,
    //         800 * 10 ** 6
    //     );

    //     vm.broadcast();
    //     investmentEngine.executeInvestment(bobInvestmentId);

    //     console.log("Bob deposited $1000 and invested $800");
    // }

    // function showPortfolioResults() internal {
    //     console.log("\nPORTFOLIO RESULTS");
    //     console.log("====================");

    //     // Alice's portfolio
    //     console.log("ALICE'S PORTFOLIO:");
    //     IInvestmentEngine.UserBalance memory aliceBalance = investmentEngine
    //         .getUserBalance(alice);
    //     console.log(
    //         "   Available Balance: $",
    //         aliceBalance.availableBalance / 10 ** 6
    //     );
    //     console.log(
    //         "   Total Invested: $",
    //         aliceBalance.totalInvested / 10 ** 6
    //     );

    //     address[] memory aliceTokens = investmentEngine.getUserTokens(alice);
    //     console.log("   Token Holdings:");
    //     for (uint256 i = 0; i < aliceTokens.length; i++) {
    //         uint256 balance = investmentEngine.getUserTokenBalance(
    //             alice,
    //             aliceTokens[i]
    //         );
    //         string memory symbol = MockERC20(aliceTokens[i]).symbol();
    //         console.log("     ", symbol, ":", balance);
    //     }

    //     uint256 alicePortfolioValue = investmentEngine.getUserPortfolioValue(
    //         alice
    //     );
    //     console.log(
    //         "   Total Portfolio Value: $",
    //         alicePortfolioValue / 10 ** 6
    //     );

    //     // Bob's portfolio
    //     console.log("\nBOB'S PORTFOLIO:");
    //     IInvestmentEngine.UserBalance memory bobBalance = investmentEngine
    //         .getUserBalance(bob);
    //     console.log(
    //         "   Available Balance: $",
    //         bobBalance.availableBalance / 10 ** 6
    //     );
    //     console.log("   Total Invested: $", bobBalance.totalInvested / 10 ** 6);

    //     uint256 bobPortfolioValue = investmentEngine.getUserPortfolioValue(bob);
    //     console.log("   Total Portfolio Value: $", bobPortfolioValue / 10 ** 6);

    //     // Platform stats
    //     uint256 tvl = investmentEngine.getTotalValueLocked();
    //     console.log("\nPLATFORM STATS:");
    //     console.log("   Total Value Locked: $", tvl / 10 ** 6);
    //     console.log("   Active Users: 2");
    //     console.log("   Investment Plans: 1");
    // }
}
