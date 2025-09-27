const express = require('express');
const router = express.Router();
const blockchain = require('../services/blockchain');

// Get user portfolio overview
router.get('/:userAddress', async (req, res) => {
  try {
    const { userAddress } = req.params;

    if (!blockchain.contracts.investmentEngine) {
      return res.status(503).json({ error: 'Investment Engine contract not available' });
    }

    // Get user balance
    const balanceResult = await blockchain.callContract(
      blockchain.contracts.investmentEngine,
      'getUserBalance',
      [userAddress]
    );

    if (!balanceResult.success) {
      return res.status(500).json({ error: balanceResult.error });
    }

    // Get user tokens
    const tokensResult = await blockchain.callContract(
      blockchain.contracts.investmentEngine,
      'getUserTokens',
      [userAddress]
    );

    if (!tokensResult.success) {
      return res.status(500).json({ error: tokensResult.error });
    }

    // Get portfolio value
    const portfolioValueResult = await blockchain.callContract(
      blockchain.contracts.investmentEngine,
      'getUserPortfolioValue',
      [userAddress]
    );

    if (!portfolioValueResult.success) {
      return res.status(500).json({ error: portfolioValueResult.error });
    }

    const balance = balanceResult.data;
    const userTokens = tokensResult.data;

    // Get individual token balances
    const tokenBalances = [];
    for (const tokenAddress of userTokens) {
      const tokenBalanceResult = await blockchain.callContract(
        blockchain.contracts.investmentEngine,
        'getUserTokenBalance',
        [userAddress, tokenAddress]
      );

      if (tokenBalanceResult.success) {
        // Try to get token info
        let tokenInfo = { symbol: 'UNKNOWN', decimals: 18 };
        try {
          // Check if we have this token in our contracts
          for (const [symbol, contract] of Object.entries(blockchain.contracts.tokens)) {
            if (contract.target.toLowerCase() === tokenAddress.toLowerCase()) {
              const symbolResult = await blockchain.callContract(contract, 'symbol');
              const decimalsResult = await blockchain.callContract(contract, 'decimals');

              if (symbolResult.success && decimalsResult.success) {
                tokenInfo = {
                  symbol: symbolResult.data,
                  decimals: parseInt(decimalsResult.data)
                };
              }
              break;
            }
          }
        } catch (error) {
          console.log('Could not fetch token info for', tokenAddress);
        }

        tokenBalances.push({
          tokenAddress,
          symbol: tokenInfo.symbol,
          balance: blockchain.formatTokenAmount(tokenBalanceResult.data, tokenInfo.decimals),
          rawBalance: tokenBalanceResult.data.toString()
        });
      }
    }

    res.json({
      success: true,
      data: {
        userAddress,
        balances: {
          totalDeposited: blockchain.formatTokenAmount(balance.totalDeposited, 6),
          availableBalance: blockchain.formatTokenAmount(balance.availableBalance, 6),
          totalInvested: blockchain.formatTokenAmount(balance.totalInvested, 6),
          pendingInvestment: blockchain.formatTokenAmount(balance.pendingInvestment, 6)
        },
        tokenHoldings: tokenBalances,
        portfolioValue: blockchain.formatTokenAmount(portfolioValueResult.data, 6),
        lastUpdated: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('Error fetching portfolio:', error);
    res.status(500).json({ error: 'Failed to fetch portfolio data' });
  }
});

// Get user token balance for specific token
router.get('/:userAddress/tokens/:tokenAddress', async (req, res) => {
  try {
    const { userAddress, tokenAddress } = req.params;

    if (!blockchain.contracts.investmentEngine) {
      return res.status(503).json({ error: 'Investment Engine contract not available' });
    }

    const result = await blockchain.callContract(
      blockchain.contracts.investmentEngine,
      'getUserTokenBalance',
      [userAddress, tokenAddress]
    );

    if (!result.success) {
      return res.status(500).json({ error: result.error });
    }

    // Try to get token info
    let tokenInfo = { symbol: 'UNKNOWN', decimals: 18 };
    try {
      for (const [symbol, contract] of Object.entries(blockchain.contracts.tokens)) {
        if (contract.target.toLowerCase() === tokenAddress.toLowerCase()) {
          const symbolResult = await blockchain.callContract(contract, 'symbol');
          const decimalsResult = await blockchain.callContract(contract, 'decimals');

          if (symbolResult.success && decimalsResult.success) {
            tokenInfo = {
              symbol: symbolResult.data,
              decimals: parseInt(decimalsResult.data)
            };
          }
          break;
        }
      }
    } catch (error) {
      console.log('Could not fetch token info for', tokenAddress);
    }

    res.json({
      success: true,
      data: {
        tokenAddress,
        symbol: tokenInfo.symbol,
        balance: blockchain.formatTokenAmount(result.data, tokenInfo.decimals),
        rawBalance: result.data.toString(),
        decimals: tokenInfo.decimals
      }
    });

  } catch (error) {
    console.error('Error fetching token balance:', error);
    res.status(500).json({ error: 'Failed to fetch token balance' });
  }
});

// Get portfolio analytics
router.get('/:userAddress/analytics', async (req, res) => {
  try {
    const { userAddress } = req.params;

    if (!blockchain.contracts.investmentEngine) {
      return res.status(503).json({ error: 'Investment Engine contract not available' });
    }

    // Get user balance
    const balanceResult = await blockchain.callContract(
      blockchain.contracts.investmentEngine,
      'getUserBalance',
      [userAddress]
    );

    // Get portfolio value
    const portfolioValueResult = await blockchain.callContract(
      blockchain.contracts.investmentEngine,
      'getUserPortfolioValue',
      [userAddress]
    );

    if (!balanceResult.success || !portfolioValueResult.success) {
      return res.status(500).json({ error: 'Failed to fetch portfolio data' });
    }

    const balance = balanceResult.data;
    const portfolioValue = parseFloat(blockchain.formatTokenAmount(portfolioValueResult.data, 6));
    const totalInvested = parseFloat(blockchain.formatTokenAmount(balance.totalInvested, 6));
    const totalDeposited = parseFloat(blockchain.formatTokenAmount(balance.totalDeposited, 6));

    // Calculate analytics
    const analytics = {
      totalPortfolioValue: portfolioValue,
      totalInvested: totalInvested,
      totalDeposited: totalDeposited,
      availableCash: parseFloat(blockchain.formatTokenAmount(balance.availableBalance, 6)),
      pendingInvestments: parseFloat(blockchain.formatTokenAmount(balance.pendingInvestment, 6)),
      investmentRatio: totalDeposited > 0 ? (totalInvested / totalDeposited) * 100 : 0,
      returnsAbsolute: portfolioValue - totalInvested,
      returnsPercentage: totalInvested > 0 ? ((portfolioValue - totalInvested) / totalInvested) * 100 : 0
    };

    res.json({
      success: true,
      data: {
        userAddress,
        analytics,
        lastUpdated: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('Error calculating analytics:', error);
    res.status(500).json({ error: 'Failed to calculate portfolio analytics' });
  }
});

module.exports = router;