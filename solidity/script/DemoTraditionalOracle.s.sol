// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/InvestmentEngineV3.sol";
import "../src/PlanManager.sol";
import "../src/tokens/MockERC20.sol";
import "../src/mocks/MockUniswapV4Router.sol";
import "../src/mocks/MockPyth.sol";
import "../src/interfaces/IPlanManager.sol";

/**
 * @title DemoTraditionalOracle
 * @dev Demonstration script for Traditional Pyth Oracle Workflow
 * Shows the pull-based oracle pattern: Fetch from Hermes → Update On-Chain → Consume
 */
contract DemoTraditionalOracle is Script {
    InvestmentEngineV3Simple public investmentEngine;
    PlanManager public planManager;
    MockUniswapV4Router public mockRouter;
    MockPyth public mockPyth;
    MockERC20 public usdc;
    MockERC20 public weth;
    MockERC20 public wbtc;

    function run() public {
        vm.startBroadcast();

        console.log("=== TRADITIONAL PYTH ORACLE WORKFLOW DEMONSTRATION ===");
        console.log("Deploying contracts for traditional oracle workflow...");

        deployContracts();
        setupSystem();
        demonstrateTraditionalWorkflow();

        vm.stopBroadcast();

        console.log("\\n=== TRADITIONAL ORACLE DEMO COMPLETE ===");
        console.log("Traditional Pyth workflow demonstrated successfully");
        console.log("Pull-based oracle pattern: Fetch -> Update -> Consume");
    }

    function deployContracts() internal {
        // Deploy tokens
        usdc = new MockERC20(
            "USD Coin",
            "USDC",
            6,
            1000000 * 10 ** 6,
            1000 * 10 ** 6
        );
        weth = new MockERC20(
            "Wrapped Ether",
            "WETH",
            18,
            1000 * 10 ** 18,
            1 * 10 ** 18
        );
        wbtc = new MockERC20(
            "Wrapped Bitcoin",
            "WBTC",
            8,
            100 * 10 ** 8,
            1 * 10 ** 6
        );

        console.log("USDC deployed at:", address(usdc));
        console.log("WETH deployed at:", address(weth));
        console.log("WBTC deployed at:", address(wbtc));

        // Deploy infrastructure
        planManager = new PlanManager();
        mockRouter = new MockUniswapV4Router();
        mockPyth = new MockPyth();

        console.log("PlanManager deployed at:", address(planManager));
        console.log("MockRouter deployed at:", address(mockRouter));
        console.log("MockPyth deployed at:", address(mockPyth));

        // Deploy InvestmentEngine
        investmentEngine = new InvestmentEngineV3Simple(
            address(planManager),
            address(mockRouter),
            address(usdc),
            address(mockPyth)
        );

        console.log("InvestmentEngine deployed at:", address(investmentEngine));
    }

    function setupSystem() internal {
        console.log("\\n=== SETTING UP SYSTEM ===");

        // Setup liquidity
        usdc.mint(address(mockRouter), 100000 * 10 ** 6);
        weth.mint(address(mockRouter), 1000 * 10 ** 18);
        wbtc.mint(address(mockRouter), 100 * 10 ** 8);

        // Set exchange rates
        mockRouter.setExchangeRate(address(usdc), address(usdc), 1e18);
        mockRouter.setExchangeRate(address(usdc), address(weth), 3e17);
        mockRouter.setExchangeRate(address(usdc), address(wbtc), 2e13);

        // Setup initial Pyth prices (these will be "old" prices)
        mockPyth.setPrice(
            0xc1da76235f64b635b813a174fd33c86363732834a2ead6079d7cda42f6e76692,
            100000000,
            -8
        ); // USDC $1.00
        mockPyth.setPrice(
            0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace,
            340000000000,
            -8
        ); // WETH $3400 (old price)
        mockPyth.setPrice(
            0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43,
            4900000000000,
            -8
        ); // WBTC $49000 (old price)

        // Create investment plan
        IPlanManager.AssetAllocation[]
            memory allocations = new IPlanManager.AssetAllocation[](3);

        allocations[0] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Stablecoin,
            tokenAddress: address(usdc),
            targetPercentage: 4000, // 40%
            minPercentage: 3500,
            maxPercentage: 4500
        });

        allocations[1] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(weth),
            targetPercentage: 4000, // 40%
            minPercentage: 3500,
            maxPercentage: 4500
        });

        allocations[2] = IPlanManager.AssetAllocation({
            assetClass: IPlanManager.AssetClass.Crypto,
            tokenAddress: address(wbtc),
            targetPercentage: 2000, // 20%
            minPercentage: 1500,
            maxPercentage: 2500
        });

        planManager.createPlan(
            IPlanManager.PlanType.Balanced,
            "Traditional Oracle Demo Portfolio",
            allocations
        );

        console.log("System setup complete");
    }

    function demonstrateTraditionalWorkflow() internal {
        console.log("\\n=== DEMONSTRATING TRADITIONAL ORACLE WORKFLOW ===");

        // Show the 3-step traditional workflow
        demonstrateStep1_FetchFromHermes();
        demonstrateStep2_UpdateOnChain();
        demonstrateStep3_ConsumeUpdatedPrices();
        demonstrateStep4_InvestWithFreshPrices();
    }

    function demonstrateStep1_FetchFromHermes() internal {
        console.log("\\n1. STEP 1: Fetch Price Updates from Hermes");
        console.log("   In real implementation:");
        console.log("   - Call Hermes API: hermesClient.getLatestPriceUpdates([priceIds])");
        console.log("   - Receive VAA (Verifiable Action Approval) data");
        console.log("   - Extract binary price update data");
        console.log("   API Endpoint: GET /api/v3/oracle/price-updates/WETH,WBTC");

        // Simulate the data structure you'd get from Hermes
        console.log("   Sample response structure:");
        console.log("   {");
        console.log("     priceUpdateData: ['0x504e41550100...', '0x504e41550100...'],");
        console.log("     symbols: ['WETH', 'WBTC'],");
        console.log("     count: 2");
        console.log("   }");
    }

    function demonstrateStep2_UpdateOnChain() internal {
        console.log("\\n2. STEP 2: Update Prices On-Chain");
        console.log("   Method: updatePriceFeeds(bytes[] calldata priceUpdateData)");

        // Simulate price update data (in real scenario, this comes from Hermes)
        bytes[] memory mockPriceUpdateData = new bytes[](2);
        mockPriceUpdateData[0] = hex"504e41550100"; // Mock VAA data for WETH
        mockPriceUpdateData[1] = hex"504e41550100"; // Mock VAA data for WBTC

        // Get update fee
        uint256 updateFee = investmentEngine.getUpdateFee(mockPriceUpdateData);
        console.log("   Required update fee:", updateFee, "wei");

        // Update prices with new values (simulating fresh data from Hermes)
        mockPyth.setPrice(
            0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace,
            350000000000,
            -8
        ); // WETH $3500 (updated price)
        mockPyth.setPrice(
            0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43,
            5000000000000,
            -8
        ); // WBTC $50000 (updated price)

        // Call updatePriceFeeds (in mock, this just validates the call)
        investmentEngine.updatePriceFeeds{value: updateFee}(mockPriceUpdateData);

        console.log("   Prices updated on-chain successfully");
        console.log("   WETH price updated: $3400 -> $3500");
        console.log("   WBTC price updated: $49000 -> $50000");
    }

    function demonstrateStep3_ConsumeUpdatedPrices() internal {
        console.log("\\n3. STEP 3: Consume Updated Prices");
        console.log("   Method: getPythPrice(bytes32 priceId)");

        bytes32 wethPriceId = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
        bytes32 wbtcPriceId = 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43;

        int256 wethPrice = investmentEngine.getPythPrice(wethPriceId);
        int256 wbtcPrice = investmentEngine.getPythPrice(wbtcPriceId);

        console.log("   Fresh WETH price from oracle:", uint256(wethPrice));
        console.log("   Fresh WBTC price from oracle:", uint256(wbtcPrice));

        // Demonstrate staleness check
        console.log("\\n   With staleness check (max 60 seconds old):");
        int256 wethPriceFresh = investmentEngine.getPythPriceNoOlderThan(wethPriceId, 60);
        console.log("   WETH price (fresh):", uint256(wethPriceFresh));

        console.log("   API Endpoint: GET /api/v3/oracle/on-chain-price/WETH?maxAge=60");
    }

    function demonstrateStep4_InvestWithFreshPrices() internal {
        console.log("\\n4. STEP 4: Investment with Fresh Prices");
        console.log("   Method: depositAndInvestWithPriceUpdate()");

        // Mint tokens for investment
        usdc.mint(msg.sender, 1000 * 10 ** 6);
        usdc.approve(address(investmentEngine), 1000 * 10 ** 6);

        // Prepare mock price update data
        bytes[] memory freshPriceData = new bytes[](2);
        freshPriceData[0] = hex"504e41550100";
        freshPriceData[1] = hex"504e41550100";

        uint256 updateFee = investmentEngine.getUpdateFee(freshPriceData);

        // Execute investment with price updates
        uint256 investmentId = investmentEngine.depositAndInvestWithPriceUpdate{
            value: updateFee
        }(1000 * 10 ** 6, 1, freshPriceData);

        console.log("   Investment executed with fresh prices");
        console.log("   Investment ID:", investmentId);
        console.log("   Price update fee paid:", updateFee, "wei");

        console.log("\\n   Benefits of Traditional Workflow:");
        console.log("   - Guaranteed fresh prices for investment execution");
        console.log("   - Reduced slippage through accurate price data");
        console.log("   - Professional-grade price feeds");
        console.log("   - Transparent on-chain price updates");
    }

    function displayWorkflowSummary() internal view {
        console.log("\\n=== TRADITIONAL PYTH ORACLE WORKFLOW SUMMARY ===");
        console.log("Step 1: Fetch from Hermes");
        console.log("  - GET /api/v3/oracle/price-updates/:symbols");
        console.log("  - Returns: price update data (VAA format)");
        console.log("");
        console.log("Step 2: Update On-Chain");
        console.log("  - Contract: updatePriceFeeds(bytes[] priceUpdateData)");
        console.log("  - Requires: msg.value = updateFee");
        console.log("  - Result: Fresh prices stored on-chain");
        console.log("");
        console.log("Step 3: Consume Prices");
        console.log("  - Contract: getPythPrice(bytes32 priceId)");
        console.log("  - Contract: getPythPriceNoOlderThan(bytes32 priceId, uint maxAge)");
        console.log("  - API: GET /api/v3/oracle/on-chain-price/:symbol");
        console.log("");
        console.log("Enhanced Investment:");
        console.log("  - Contract: depositAndInvestWithPriceUpdate()");
        console.log("  - API: POST /api/v3/invest-with-price-update");
        console.log("  - Benefit: Investment executed with guaranteed fresh prices");
        console.log("");
        console.log("TRADITIONAL WORKFLOW READY FOR PRODUCTION!");
    }
}