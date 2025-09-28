const express = require("express");
const { ethers } = require("ethers");
const router = express.Router();

// Import configuration and validation
const {
  getCurrentNetwork,
  initializeProvider,
  createInvestmentEngineContract,
  createPlanManagerContract,
  createTokenContract,
} = require("../config/contracts");

const {
  validateUserAddress,
  validateInvestmentId,
  validatePlanId,
  validateQuoteRequest,
  validateInvestmentPreparation,
  validatePagination,
  validateEventQuery,
  rateLimits,
} = require("../middleware/validation");

// Import Pyth services for price feeds
const PythHermesService = require("../services/pythHermesService");
const PythOracleService = require("../services/pythOracleService");

// Initialize provider and contracts
const provider = initializeProvider();
const investmentEngine = createInvestmentEngineContract(provider);
const planManager = createPlanManagerContract(provider);
const network = getCurrentNetwork();

// Initialize Pyth services
const pythHermesService = new PythHermesService();
const pythOracleService = new PythOracleService(
  process.env.RPC_URL,
  network.contracts.PYTH
);

/**
 * @route GET /api/v3/status
 * @desc Get contract status and configuration
 * @access Public
 */
router.get("/status", async (req, res) => {
  try {
    const [
      owner,
      planManagerAddress,
      routerAddress,
      baseToken,
      fee,
      slippage,
      totalInvestments,
    ] = await Promise.all([
      investmentEngine.owner(),
      investmentEngine.planManager(),
      investmentEngine.router(),
      investmentEngine.baseToken(),
      investmentEngine.fee(),
      investmentEngine.slippage(),
      investmentEngine.getTotalInvestments(),
    ]);

    res.json({
      success: true,
      data: {
        contractAddress: network.contracts.INVESTMENT_ENGINE_V3,
        owner,
        planManager: planManagerAddress,
        router: routerAddress,
        baseToken,
        fee: fee.toString(),
        slippage: slippage.toString(),
        totalInvestments: totalInvestments.toString(),
        supportedTokens: network.contracts.TOKENS,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route GET /api/v3/plans
 * @desc Get all available investment plans
 * @access Public
 */
router.get("/plans", async (req, res) => {
  try {
    const totalPlans = await planManager.getTotalPlans();
    const plans = [];

    for (let i = 1; i <= totalPlans; i++) {
      const plan = await planManager.getPlan(i);
      plans.push({
        planId: plan.planId.toString(),
        planType: plan.planType.toString(),
        name: plan.name,
        allocations: plan.allocations.map((allocation) => ({
          assetClass: allocation.assetClass.toString(),
          tokenAddress: allocation.tokenAddress,
          targetPercentage: allocation.targetPercentage.toString(),
          minPercentage: allocation.minPercentage.toString(),
          maxPercentage: allocation.maxPercentage.toString(),
        })),
        riskScore: plan.riskScore.toString(),
        isActive: plan.isActive,
        createdAt: plan.createdAt.toString(),
        updatedAt: plan.updatedAt.toString(),
      });
    }

    res.json({
      success: true,
      data: {
        totalPlans: totalPlans.toString(),
        plans,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route GET /api/v3/plans/:planId
 * @desc Get specific investment plan details
 * @access Public
 */
router.get("/plans/:planId", validatePlanId, async (req, res) => {
  try {
    const { planId } = req.params;
    const plan = await planManager.getPlan(planId);

    if (!plan.isActive) {
      return res.status(404).json({
        success: false,
        error: "Plan not found or inactive",
      });
    }

    res.json({
      success: true,
      data: {
        planId: plan.planId.toString(),
        planType: plan.planType.toString(),
        name: plan.name,
        allocations: plan.allocations.map((allocation) => ({
          assetClass: allocation.assetClass.toString(),
          tokenAddress: allocation.tokenAddress,
          targetPercentage: allocation.targetPercentage.toString(),
          minPercentage: allocation.minPercentage.toString(),
          maxPercentage: allocation.maxPercentage.toString(),
        })),
        riskScore: plan.riskScore.toString(),
        isActive: plan.isActive,
        createdAt: plan.createdAt.toString(),
        updatedAt: plan.updatedAt.toString(),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route POST /api/v3/quote
 * @desc Get investment quote for a specific amount and plan
 * @access Public
 */
router.post("/quote", validateQuoteRequest, async (req, res) => {
  try {
    const { amount, planId } = req.body;

    if (!amount || !planId) {
      return res.status(400).json({
        success: false,
        error: "Amount and planId are required",
      });
    }

    const plan = await planManager.getPlan(planId);

    if (!plan.isActive) {
      return res.status(404).json({
        success: false,
        error: "Plan not found or inactive",
      });
    }

    // Get current prices for all assets in the plan
    const tokenSymbols = [];
    const tokenAddressToSymbol = {};

    // Map token addresses to symbols
    for (const [symbol, address] of Object.entries(network.contracts.TOKENS)) {
      tokenAddressToSymbol[address.toLowerCase()] = symbol;
    }

    plan.allocations.forEach((allocation) => {
      const symbol =
        tokenAddressToSymbol[allocation.tokenAddress.toLowerCase()];
      if (symbol && !tokenSymbols.includes(symbol)) {
        tokenSymbols.push(symbol);
      }
    });

    // Fetch current prices
    let currentPrices = {};
    try {
      if (tokenSymbols.length > 0) {
        currentPrices = await pythHermesService.getMultipleAssetPrices(
          tokenSymbols
        );
      }
    } catch (priceError) {
      console.warn("Failed to fetch current prices:", priceError.message);
    }

    // Calculate allocation breakdown with real-time pricing
    const allocations = plan.allocations.map((allocation) => {
      const allocationAmount =
        (BigInt(amount) * BigInt(allocation.targetPercentage)) / BigInt(10000);
      const symbol =
        tokenAddressToSymbol[allocation.tokenAddress.toLowerCase()];

      let priceInfo = null;
      let estimatedTokens = null;

      if (symbol && currentPrices[symbol]) {
        priceInfo = {
          symbol: symbol,
          price: currentPrices[symbol].formattedPriceString,
          lastUpdated: currentPrices[symbol].lastUpdated,
        };

        // Estimate tokens to be received (rough calculation)
        const usdAmount = Number(allocationAmount) / 1e6; // Assuming USDC has 6 decimals
        estimatedTokens = (
          usdAmount / currentPrices[symbol].formattedPrice
        ).toFixed(6);
      }

      return {
        tokenAddress: allocation.tokenAddress,
        tokenSymbol: symbol || "UNKNOWN",
        assetClass: allocation.assetClass.toString(),
        targetPercentage: allocation.targetPercentage.toString(),
        amount: allocationAmount.toString(),
        amountUSD: (Number(allocationAmount) / 1e6).toFixed(2),
        currentPrice: priceInfo,
        estimatedTokensReceived: estimatedTokens,
      };
    });

    res.json({
      success: true,
      data: {
        planId: plan.planId.toString(),
        planName: plan.name,
        totalAmount: amount.toString(),
        totalAmountUSD: (Number(amount) / 1e6).toFixed(2),
        allocations,
        estimatedGas: "300000", // Rough estimate
        slippage: (await investmentEngine.slippage()).toString(),
        priceDataSource: "Pyth Network Hermes",
        quoteTimestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route POST /api/v3/prepare-investment
 * @desc Prepare investment transaction data
 * @access Public
 */
router.post(
  "/prepare-investment",
  validateInvestmentPreparation,
  async (req, res) => {
    try {
      const { userAddress, amount, planId } = req.body;

      if (!userAddress || !amount || !planId) {
        return res.status(400).json({
          success: false,
          error: "userAddress, amount, and planId are required",
        });
      }

      // Validate Ethereum address
      if (!ethers.isAddress(userAddress)) {
        return res.status(400).json({
          success: false,
          error: "Invalid Ethereum address",
        });
      }

      // Check if plan exists
      const plan = await planManager.getPlan(planId);
      if (!plan.isActive) {
        return res.status(404).json({
          success: false,
          error: "Plan not found or inactive",
        });
      }

      // Get current gas price
      const feeData = await provider.getFeeData();

      // Prepare transaction data
      const investmentEngineInterface = new ethers.Interface(
        require("../abis/InvestmentEngineV3.json")
      );
      const txData = investmentEngineInterface.encodeFunctionData(
        "depositAndInvest",
        [amount, planId]
      );

      // Check user's PYUSD balance and allowance
      const pyusdContract = createTokenContract("PYUSD", provider);
      const [balance, allowance] = await Promise.all([
        pyusdContract.balanceOf(userAddress),
        pyusdContract.allowance(
          userAddress,
          network.contracts.INVESTMENT_ENGINE_V3
        ),
      ]);

      const needsApproval = BigInt(allowance) < BigInt(amount);

      res.json({
        success: true,
        data: {
          needsApproval,
          currentBalance: balance.toString(),
          currentAllowance: allowance.toString(),
          requiredAmount: amount.toString(),
          transactions: needsApproval
            ? [
                {
                  type: "approval",
                  to: network.contracts.TOKENS.PYUSD,
                  data: new ethers.Interface(
                    require("../abis/ERC20.json")
                  ).encodeFunctionData("approve", [
                    network.contracts.INVESTMENT_ENGINE_V3,
                    amount,
                  ]),
                  gasLimit: "60000",
                },
                {
                  type: "investment",
                  to: network.contracts.INVESTMENT_ENGINE_V3,
                  data: txData,
                  gasLimit: "350000",
                },
              ]
            : [
                {
                  type: "investment",
                  to: network.contracts.INVESTMENT_ENGINE_V3,
                  data: txData,
                  gasLimit: "350000",
                },
              ],
          gasPrice: feeData.gasPrice ? feeData.gasPrice.toString() : null,
          maxFeePerGas: feeData.maxFeePerGas
            ? feeData.maxFeePerGas.toString()
            : null,
          maxPriorityFeePerGas: feeData.maxPriorityFeePerGas
            ? feeData.maxPriorityFeePerGas.toString()
            : null,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * @route GET /api/v3/investments/:investmentId
 * @desc Get investment details by ID
 * @access Public
 */
router.get(
  "/investments/:investmentId",
  validateInvestmentId,
  async (req, res) => {
    try {
      const { investmentId } = req.params;
      const investment = await investmentEngine.getInvestment(investmentId);

      if (investment.user === ethers.ZeroAddress) {
        return res.status(404).json({
          success: false,
          error: "Investment not found",
        });
      }

      res.json({
        success: true,
        data: {
          investmentId,
          user: investment.user,
          planId: investment.planId.toString(),
          amount: investment.amount.toString(),
          timestamp: investment.timestamp.toString(),
          blockTimestamp: new Date(
            Number(investment.timestamp) * 1000
          ).toISOString(),
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * @route GET /api/v3/users/:userAddress/investments
 * @desc Get all investments for a user
 * @access Public
 */
router.get(
  "/users/:userAddress/investments",
  validateUserAddress,
  validatePagination,
  async (req, res) => {
    try {
      const { userAddress } = req.params;
      const { page = 1, limit = 10 } = req.query;

      if (!ethers.isAddress(userAddress)) {
        return res.status(400).json({
          success: false,
          error: "Invalid Ethereum address",
        });
      }

      // Get total investments to know how many to check
      const totalInvestments = await investmentEngine.getTotalInvestments();
      const userInvestments = [];

      // This is not efficient for production - should use events/subgraph
      for (let i = 1; i <= totalInvestments; i++) {
        try {
          const investment = await investmentEngine.getInvestment(i);
          if (investment.user.toLowerCase() === userAddress.toLowerCase()) {
            userInvestments.push({
              investmentId: i.toString(),
              planId: investment.planId.toString(),
              amount: investment.amount.toString(),
              timestamp: investment.timestamp.toString(),
              blockTimestamp: new Date(
                Number(investment.timestamp) * 1000
              ).toISOString(),
            });
          }
        } catch (err) {
          // Skip invalid investments
          continue;
        }
      }

      // Simple pagination
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + parseInt(limit);
      const paginatedInvestments = userInvestments.slice(startIndex, endIndex);

      res.json({
        success: true,
        data: {
          investments: paginatedInvestments,
          pagination: {
            currentPage: parseInt(page),
            totalItems: userInvestments.length,
            itemsPerPage: parseInt(limit),
            totalPages: Math.ceil(userInvestments.length / limit),
          },
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * @route GET /api/v3/users/:userAddress/portfolio
 * @desc Get user's current portfolio (requires additional tracking)
 * @access Public
 */
router.get(
  "/users/:userAddress/portfolio",
  validateUserAddress,
  async (req, res) => {
    try {
      const { userAddress } = req.params;

      if (!ethers.isAddress(userAddress)) {
        return res.status(400).json({
          success: false,
          error: "Invalid Ethereum address",
        });
      }

      // Get token balances for the user
      const tokenBalances = {};

      for (const [symbol, address] of Object.entries(
        network.contracts.TOKENS
      )) {
        try {
          const tokenContract = createTokenContract(symbol, provider);
          const balance = await tokenContract.balanceOf(userAddress);
          const decimals = await tokenContract.decimals();
          const name = await tokenContract.name();

          tokenBalances[symbol] = {
            address,
            name,
            symbol,
            balance: balance.toString(),
            decimals: decimals.toString(),
            balanceFormatted: ethers.formatUnits(balance, decimals),
          };
        } catch (err) {
          tokenBalances[symbol] = {
            address,
            balance: "0",
            error: "Unable to fetch balance",
          };
        }
      }

      res.json({
        success: true,
        data: {
          userAddress,
          tokenBalances,
          lastUpdated: new Date().toISOString(),
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * @route GET /api/v3/events
 * @desc Get recent investment events
 * @access Public
 */
router.get(
  "/events",
  rateLimits.events,
  validateEventQuery,
  async (req, res) => {
    try {
      const { fromBlock = "latest", limit = 50 } = req.query;

      // Get recent InvestmentExecuted events
      const eventFilter = investmentEngine.filters.InvestmentExecuted();
      const currentBlock = await provider.getBlockNumber();
      const startBlock =
        fromBlock === "latest" ? currentBlock - 1000 : parseInt(fromBlock);

      const events = await investmentEngine.queryFilter(
        eventFilter,
        Math.max(startBlock, 0),
        currentBlock
      );

      const formattedEvents = events.slice(-limit).map((event) => ({
        transactionHash: event.transactionHash,
        blockNumber: event.blockNumber,
        investmentId: event.args.investmentId.toString(),
        user: event.args.user,
        planId: event.args.planId.toString(),
        amount: event.args.amount.toString(),
        timestamp: event.args ? new Date().toISOString() : null, // Would need block timestamp
      }));

      res.json({
        success: true,
        data: {
          events: formattedEvents,
          totalEvents: events.length,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * @route GET /api/v3/stats
 * @desc Get platform statistics
 * @access Public
 */
router.get("/stats", async (req, res) => {
  try {
    const [totalInvestments, totalPlans] = await Promise.all([
      investmentEngine.getTotalInvestments(),
      planManager.getTotalPlans(),
    ]);

    // Calculate total volume (would need to aggregate all investments)
    let totalVolume = BigInt(0);
    const investmentCount = Number(totalInvestments);

    for (let i = 1; i <= Math.min(investmentCount, 100); i++) {
      // Limit for performance
      try {
        const investment = await investmentEngine.getInvestment(i);
        totalVolume += BigInt(investment.amount);
      } catch (err) {
        continue;
      }
    }

    res.json({
      success: true,
      data: {
        totalInvestments: totalInvestments.toString(),
        totalPlans: totalPlans.toString(),
        totalVolume: totalVolume.toString(),
        totalVolumeFormatted: ethers.formatUnits(totalVolume, 6), // Assuming USDC (6 decimals)
        contracts: {
          investmentEngine: network.contracts.INVESTMENT_ENGINE_V3,
          planManager: network.contracts.PLAN_MANAGER,
          router: network.contracts.UNISWAP_V4_ROUTER,
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route POST /api/v3/simulate-investment
 * @desc Simulate an investment to showcase the flow
 * @access Public
 */
router.post(
  "/simulate-investment",
  validateInvestmentPreparation,
  async (req, res) => {
    try {
      const { userAddress, amount, planId } = req.body;

      if (!userAddress || !amount || !planId) {
        return res.status(400).json({
          success: false,
          error: "userAddress, amount, and planId are required",
        });
      }

      const plan = await planManager.getPlan(planId);
      if (!plan.isActive) {
        return res.status(404).json({
          success: false,
          error: "Plan not found or inactive",
        });
      }

      // Simulate the investment allocation and swaps
      const simulatedResults = await Promise.all(
        plan.allocations.map(async (allocation) => {
          const allocationAmount =
            (BigInt(amount) * BigInt(allocation.targetPercentage)) /
            BigInt(10000);

          // For the base token, the amount is the same
          if (
            allocation.tokenAddress.toLowerCase() ===
            network.contracts.TOKENS.USDC.toLowerCase()
          ) {
            return {
              tokenAddress: allocation.tokenAddress,
              amountIn: allocationAmount.toString(),
              amountOut: allocationAmount.toString(), // No swap needed
            };
          }

          // For other tokens, simulate a swap (e.g., with a 5% fee/slippage)
          // In a real scenario, you would use a quoter contract to get a more accurate estimate
          const simulatedAmountOut =
            (allocationAmount * BigInt(9500)) / BigInt(10000);

          return {
            tokenAddress: allocation.tokenAddress,
            amountIn: allocationAmount.toString(),
            amountOut: simulatedAmountOut.toString(),
          };
        })
      );

      res.json({
        success: true,
        message: "Investment simulation successful",
        data: {
          userAddress,
          planId: plan.planId.toString(),
          planName: plan.name,
          investmentAmount: amount.toString(),
          simulatedTokensToUser: simulatedResults,
          note: "This is a simulation. In a real investment, the user would sign a transaction to execute the swaps.",
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * @route GET /api/v3/price/:tokenSymbol
 * @desc Get live price for a token using Pyth Hermes
 * @access Public
 */
router.get("/price/:tokenSymbol", async (req, res) => {
  try {
    const { tokenSymbol } = req.params;

    // Check if token is supported in our network config
    const tokenAddress = network.contracts.TOKENS[tokenSymbol.toUpperCase()];
    if (!tokenAddress) {
      return res.status(404).json({
        success: false,
        error: "Token symbol not supported in network configuration",
      });
    }

    // Fetch real-time price from Pyth Hermes
    const priceData = await pythHermesService.getAssetPrice(tokenSymbol);
    console.log(JSON.stringify(priceData));
    res.json({
      success: true,
      data: {
        tokenSymbol: priceData.symbol,
        tokenAddress: tokenAddress,
        price: priceData.price,
        formattedPrice: priceData.formattedPriceString,
        confidence: priceData.confidence,
        lastUpdated: priceData.lastUpdated,
        publishTime: priceData.publishTime,
        source: priceData.source,
        network: network.name,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route GET /api/v3/prices
 * @desc Get all supported asset prices from Pyth Hermes
 * @access Public
 */
router.get("/prices", async (req, res) => {
  try {
    const allPrices = await pythHermesService.getAllSupportedPrices();

    res.json({
      success: true,
      data: {
        prices: allPrices,
        totalAssets: Object.keys(allPrices).length,
        lastUpdated: new Date().toISOString(),
        source: "Pyth Network Hermes",
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route POST /api/v3/prices/multiple
 * @desc Get prices for multiple assets
 * @access Public
 */
router.post("/prices/multiple", async (req, res) => {
  try {
    const { symbols } = req.body;

    if (!symbols || !Array.isArray(symbols) || symbols.length === 0) {
      return res.status(400).json({
        success: false,
        error: "symbols array is required and must not be empty",
      });
    }

    if (symbols.length > 20) {
      return res.status(400).json({
        success: false,
        error: "Maximum 20 symbols allowed per request",
      });
    }

    const prices = await pythHermesService.getMultipleAssetPrices(symbols);

    res.json({
      success: true,
      data: {
        prices,
        requestedSymbols: symbols,
        retrievedCount: Object.keys(prices).length,
        lastUpdated: new Date().toISOString(),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route GET /api/v3/prices/supported
 * @desc Get list of all supported asset symbols
 * @access Public
 */
router.get("/prices/supported", async (req, res) => {
  try {
    const supportedSymbols = pythHermesService.getSupportedSymbols();

    res.json({
      success: true,
      data: {
        supportedSymbols,
        totalCount: supportedSymbols.length,
        description:
          "List of all asset symbols supported by Pyth Hermes price feeds",
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route GET /api/v3/prices/health
 * @desc Health check for Pyth Hermes service
 * @access Public
 */
router.get("/prices/health", async (req, res) => {
  try {
    const healthStatus = await pythHermesService.healthCheck();

    const statusCode = healthStatus.status === "healthy" ? 200 : 503;

    res.status(statusCode).json({
      success: healthStatus.status === "healthy",
      data: healthStatus,
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      error: error.message,
      status: "unhealthy",
    });
  }
});

/**
 * @route POST /api/v3/execute-investment-for-test
 * @desc (FOR TESTING ONLY) Execute an investment directly using a private key
 * @access Public
 */
router.post("/execute-investment-for-test", async (req, res) => {
  try {
    const { privateKey, planId, amount } = req.body;

    if (!privateKey || !planId || !amount) {
      return res.status(400).json({
        success: false,
        error: "privateKey, planId, and amount are required",
      });
    }

    // WARNING: This is highly insecure and for testing purposes only.
    const testWallet = new ethers.Wallet(privateKey, provider);

    // Connect to contracts with the test wallet
    const pyusdContract = createTokenContract("PYUSD", provider).connect(
      testWallet
    );
    const investmentEngineWithSigner = investmentEngine.connect(testWallet);

    // 1. Approve the investment engine to spend PYUSD
    const approveTx = await pyusdContract.approve(
      network.contracts.INVESTMENT_ENGINE_V3,
      amount
    );
    await approveTx.wait();

    // 2. Execute the investment
    const investTx = await investmentEngineWithSigner.depositAndInvest(
      amount,
      planId
    );
    const receipt = await investTx.wait();

    res.json({
      success: true,
      message: "Test investment executed successfully!",
      data: {
        userAddress: testWallet.address,
        planId,
        amount,
        approvalTransactionHash: approveTx.hash,
        investmentTransactionHash: investTx.hash,
        blockNumber: receipt.blockNumber,
      },
      warning:
        "This endpoint is for testing only and is highly insecure. Do not use in production.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ===== TRADITIONAL PYTH ORACLE WORKFLOW ENDPOINTS =====

/**
 * @route GET /api/v3/oracle/price-updates/:symbols
 * @desc Fetch price update data from Hermes (Step 1 of traditional workflow)
 * @access Public
 */
router.get("/oracle/price-updates/:symbols", async (req, res) => {
  try {
    const symbols = req.params.symbols.split(",");
    const priceUpdates = await pythOracleService.fetchPriceUpdates(symbols);

    res.json({
      success: true,
      data: {
        workflow: "traditional",
        step: 1,
        description: "Price updates fetched from Hermes",
        priceUpdateData: priceUpdates.priceUpdateData,
        symbols: priceUpdates.symbols,
        count: priceUpdates.count,
        timestamp: priceUpdates.timestamp,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route POST /api/v3/oracle/calculate-fee
 * @desc Calculate update fee for price update data (Step 2a of traditional workflow)
 * @access Public
 */
router.post("/oracle/calculate-fee", async (req, res) => {
  try {
    const { priceUpdateData } = req.body;

    if (!priceUpdateData || !Array.isArray(priceUpdateData)) {
      return res.status(400).json({
        success: false,
        error: "priceUpdateData array is required",
      });
    }

    const fee = await pythOracleService.calculateUpdateFee(priceUpdateData);

    res.json({
      success: true,
      data: {
        workflow: "traditional",
        step: "2a",
        description: "Update fee calculated",
        fee: fee,
        feeInEth: (Number(fee) / 1e18).toFixed(6),
        priceUpdatesCount: priceUpdateData.length,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route GET /api/v3/oracle/on-chain-price/:symbol
 * @desc Read price from on-chain oracle (Step 3 of traditional workflow)
 * @access Public
 */
router.get("/oracle/on-chain-price/:symbol", async (req, res) => {
  try {
    const { symbol } = req.params;
    const { maxAge } = req.query;

    const price = await pythOracleService.readOnChainPrice(
      symbol,
      maxAge ? parseInt(maxAge) : null
    );

    res.json({
      success: true,
      data: {
        workflow: "traditional",
        step: 3,
        description: "Price read from on-chain oracle",
        ...price,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route GET /api/v3/oracle/health
 * @desc Health check for traditional oracle service
 * @access Public
 */
router.get("/oracle/health", async (req, res) => {
  try {
    const health = await pythOracleService.healthCheck();
    res.json({
      success: true,
      data: health,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * @route GET /api/v3/oracle/supported-assets
 * @desc Get supported assets for traditional oracle
 * @access Public
 */
router.get("/oracle/supported-assets", (req, res) => {
  try {
    const symbols = pythOracleService.getSupportedSymbols();
    const priceFeeds = symbols.map((symbol) => ({
      symbol,
      priceId: pythOracleService.getPriceFeedId(symbol),
    }));

    res.json({
      success: true,
      data: {
        supportedAssets: symbols,
        priceFeeds: priceFeeds,
        count: symbols.length,
        workflow: "traditional",
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// /**
//  * @route POST /api/v3/invest-with-price-update
//  * @desc Execute investment with fresh price updates (enhanced traditional workflow)
//  * @access Public
//  */
// router.post("/invest-with-price-update",
//   rateLimits.investment,
//   validateInvestmentPreparation,
//   async (req, res) => {
//     try {
//       const { amount, planId, symbols } = req.body;

//       // Validate required fields
//       if (!amount || !planId) {
//         return res.status(400).json({
//           success: false,
//           error: 'amount and planId are required'
//         });
//       }

//       // Step 1: Fetch price updates for relevant symbols
//       const assetsToUpdate = symbols || ['WETH', 'WBTC', 'LINK'];
//       const priceUpdates = await pythOracleService.fetchPriceUpdates(assetsToUpdate);

//       // Step 2: Calculate required fee
//       const fee = await pythOracleService.calculateUpdateFee(priceUpdates.priceUpdateData);

//       res.json({
//         success: true,
//         data: {
//           workflow: 'traditional-investment',
//           description: 'Ready for investment with fresh price updates',
//           priceUpdateData: priceUpdates.priceUpdateData,
//           requiredFee: fee,
//           feeInEth: (Number(fee) / 1e18).toFixed(6),
//           symbols: priceUpdates.symbols,
//           instructions: {
//             step1: 'Call depositAndInvestWithPriceUpdate on the smart contract',
//             step2: 'Include priceUpdateData in the call',
//             step3: 'Send the requiredFee as msg.value',
//             step4: 'The contract will update prices and execute investment'
//           },
//           contractMethod: 'depositAndInvestWithPriceUpdate(uint256,uint256,bytes[])',
//           contractParams: {
//             amount: amount,
//             planId: planId,
//             priceUpdateData: priceUpdates.priceUpdateData
//           }
//         }
//       });
//     } catch (error) {
//       res.status(500).json({
//         success: false,
//         error: error.message
//       });
//     }
//   }
// );

module.exports = router;
