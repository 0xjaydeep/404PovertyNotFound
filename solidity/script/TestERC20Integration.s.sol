// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/PlanManager.sol";
import "../src/InvestmentEngineV2.sol";
import "../src/tokens/MockERC20.sol";
import "../src/interfaces/IPlanManager.sol";

contract TestERC20Integration is Script {
    PlanManager public planManager;
    InvestmentEngineV2 public investmentEngine;
    MockERC20 public usdc;
    MockERC20 public wbtc;
    MockERC20 public weth;
    MockERC20 public link;

    address testUser1 = makeAddr("testUser1");
    address testUser2 = makeAddr("testUser2");

    function run() public {
        vm.startBroadcast();

        console.log("=== ERC20 Integration Test ===");
        console.log("Deployer:", msg.sender);

        // Deploy tokens first
        deployTokens();

        // Deploy core contracts
        deployCoreContracts();

        // Setup token reserves in contract
        setupTokenReserves();

        // Create investment plans with real token addresses
        uint256 planId = createTokenBasedPlan();

        // Test the full flow
        testTokenDepositAndInvestment(planId);

        vm.stopBroadcast();

        console.log("\n=== ERC20 Integration Test Complete ===");
    }

    function deployTokens() internal {
        console.log("\n=== Deploying Mock Tokens ===");

        usdc = new MockERC20(
            "Mock USD Coin", "USDC", 6,
            1000000 * 10**6,  // 1M USDC
            1000 * 10**6      // 1000 USDC faucet
        );

        wbtc = new MockERC20(
            "Mock Wrapped Bitcoin", "WBTC", 8,
            100 * 10**8,      // 100 WBTC
            1 * 10**6         // 0.01 WBTC faucet
        );

        weth = new MockERC20(
            "Mock Wrapped Ether", "WETH", 18,
            1000 * 10**18,    // 1000 WETH
            1 * 10**18        // 1 WETH faucet
        );

        link = new MockERC20(
            "Mock Chainlink", "LINK", 18,
            10000 * 10**18,   // 10k LINK
            100 * 10**18      // 100 LINK faucet
        );

        console.log("USDC deployed at:", address(usdc));
        console.log("WBTC deployed at:", address(wbtc));
        console.log("WETH deployed at:", address(weth));
        console.log("LINK deployed at:", address(link));
    }

    function deployCoreContracts() internal {
        console.log("\n=== Deploying Core Contracts ===");

        planManager = new PlanManager();
        console.log("PlanManager deployed at:", address(planManager));

        // Use USDC as base token
        investmentEngine = new InvestmentEngineV2(address(usdc));
        console.log("InvestmentEngineV2 deployed at:", address(investmentEngine));

        investmentEngine.setPlanManager(address(planManager));
        console.log("Contracts connected");
    }

    function setupTokenReserves() internal {
        console.log("\n=== Setting up Token Reserves ===");

        // Transfer reasonable amounts based on initial supply
        usdc.transfer(address(investmentEngine), 100000 * 10**6);   // 100k USDC (out of 1M)
        wbtc.transfer(address(investmentEngine), 50 * 10**8);       // 50 WBTC (out of 100)
        weth.transfer(address(investmentEngine), 500 * 10**18);     // 500 WETH (out of 1000)
        link.transfer(address(investmentEngine), 5000 * 10**18);    // 5k LINK (out of 10k)

        console.log("Token reserves set up for simulated purchases");
    }

    function createTokenBasedPlan() internal returns (uint256) {
        console.log("\n=== Creating Token-Based Investment Plan ===");

        IPlanManager.AssetAllocation[] memory allocations = new IPlanManager.AssetAllocation[](4);

        // 40% WETH, 30% WBTC, 20% LINK, 10% USDC
        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(weth),
            targetPercentage: 4000,
            minPercentage: 3500,
            maxPercentage: 4500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(wbtc),
            targetPercentage: 3000,
            minPercentage: 2500,
            maxPercentage: 3500
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(link),
            targetPercentage: 2000,
            minPercentage: 1500,
            maxPercentage: 2500
        });

        allocations[3] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: address(usdc),
            targetPercentage: 1000,
            minPercentage: 500,
            maxPercentage: 1500
        });

        uint256 planId = planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Multi-Token Balanced Portfolio",
            allocations
        );

        console.log("Created plan with ID:", planId);
        console.log("Plan uses real ERC20 token addresses");

        return planId;
    }

    function testTokenDepositAndInvestment(uint256 planId) internal {
        console.log("\n=== Testing Token Deposit and Investment ===");

        // Give test users some tokens
        usdc.mint(testUser1, 5000 * 10**6); // 5000 USDC
        usdc.mint(testUser2, 3000 * 10**6); // 3000 USDC

        console.log("Minted tokens to test users");

        vm.stopBroadcast();

        // User 1 deposits USDC tokens
        vm.broadcast(testUser1);
        usdc.approve(address(investmentEngine), 2000 * 10**6);

        vm.broadcast(testUser1);
        investmentEngine.depositToken(
            address(usdc),
            2000 * 10**6, // 2000 USDC
            IInvestmentEngine.DepositType.Salary
        );

        console.log("User 1 deposited 2000 USDC tokens");

        // Check user balance
        IInvestmentEngine.UserBalance memory balance = investmentEngine.getUserBalance(testUser1);
        console.log("User 1 available balance:", balance.availableBalance);

        // User 1 creates an investment
        vm.broadcast(testUser1);
        uint256 investmentId = investmentEngine.invest(planId, 1000 * 10**6); // Invest 1000 USDC worth
        console.log("Investment created with ID:", investmentId);

        // Execute the investment (owner action)
        vm.broadcast();
        investmentEngine.executeInvestment(investmentId);
        console.log("Investment executed - tokens should be allocated according to plan");

        // Check user's token holdings
        console.log("\n=== User Token Holdings After Investment ===");

        address[] memory userTokens = investmentEngine.getUserTokens(testUser1);
        console.log("User holds", userTokens.length, "different tokens");

        for (uint256 i = 0; i < userTokens.length; i++) {
            uint256 tokenBalance = investmentEngine.getUserTokenBalance(testUser1, userTokens[i]);
            string memory symbol = MockERC20(userTokens[i]).symbol();
            console.log("Token", symbol, "balance:", tokenBalance);
        }

        // Check portfolio value
        uint256 portfolioValue = investmentEngine.getUserPortfolioValue(testUser1);
        console.log("Total portfolio value:", portfolioValue);

        // Final balance check
        IInvestmentEngine.UserBalance memory finalBalance = investmentEngine.getUserBalance(testUser1);
        console.log("\nFinal user balance:");
        console.log("  Available:", finalBalance.availableBalance);
        console.log("  Invested:", finalBalance.totalInvested);
        console.log("  Pending:", finalBalance.pendingInvestment);
    }
}