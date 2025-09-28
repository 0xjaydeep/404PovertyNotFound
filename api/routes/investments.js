const express = require('express');
const router = express.Router();
const blockchain = require('../services/blockchain');

// Create new investment
router.post('/', async (req, res) => {
  try {
    const { userAddress, planId, amount } = req.body;

    if (!userAddress || !planId || !amount) {
      return res.status(400).json({ error: 'Missing required fields: userAddress, planId, amount' });
    }

    if (!blockchain.contracts.investmentEngine) {
      return res.status(503).json({ error: 'Investment Engine contract not available' });
    }

    // Convert amount to proper format (assuming USDC with 6 decimals)
    const formattedAmount = blockchain.parseTokenAmount(amount, 6);

    const result = await blockchain.executeTransaction(
      blockchain.contracts.investmentEngine,
      'invest',
      [planId, formattedAmount]
    );

    if (!result.success) {
      return res.status(500).json({ error: result.error });
    }

    res.status(201).json({
      success: true,
      message: 'Investment created successfully',
      transactionHash: result.txHash,
      blockNumber: result.blockNumber
    });

  } catch (error) {
    console.error('Error creating investment:', error);
    res.status(500).json({ error: 'Failed to create investment' });
  }
});

// Execute pending investment (admin only)
router.post('/:investmentId/execute', async (req, res) => {
  try {
    const { investmentId } = req.params;

    if (!blockchain.contracts.investmentEngine) {
      return res.status(503).json({ error: 'Investment Engine contract not available' });
    }

    const result = await blockchain.executeTransaction(
      blockchain.contracts.investmentEngine,
      'executeInvestment',
      [investmentId]
    );

    if (!result.success) {
      return res.status(500).json({ error: result.error });
    }

    res.json({
      success: true,
      message: 'Investment executed successfully',
      transactionHash: result.txHash,
      blockNumber: result.blockNumber
    });

  } catch (error) {
    console.error('Error executing investment:', error);
    res.status(500).json({ error: 'Failed to execute investment' });
  }
});

// Deposit tokens
router.post('/deposit', async (req, res) => {
  try {
    const { userAddress, tokenAddress, amount, depositType } = req.body;

    if (!userAddress || !tokenAddress || !amount || depositType === undefined) {
      return res.status(400).json({
        error: 'Missing required fields: userAddress, tokenAddress, amount, depositType'
      });
    }

    if (!blockchain.contracts.investmentEngine) {
      return res.status(503).json({ error: 'Investment Engine contract not available' });
    }

    // Get token decimals to format amount properly
    let decimals = 18; // Default
    const tokenSymbol = tokenAddress.toLowerCase();
    if (tokenSymbol.includes('usdc')) decimals = 6;
    else if (tokenSymbol.includes('wbtc')) decimals = 8;

    const formattedAmount = blockchain.parseTokenAmount(amount, decimals);

    const result = await blockchain.executeTransaction(
      blockchain.contracts.investmentEngine,
      'depositToken',
      [tokenAddress, formattedAmount, depositType]
    );

    if (!result.success) {
      return res.status(500).json({ error: result.error });
    }

    res.status(201).json({
      success: true,
      message: 'Deposit successful',
      transactionHash: result.txHash,
      blockNumber: result.blockNumber
    });

  } catch (error) {
    console.error('Error depositing tokens:', error);
    res.status(500).json({ error: 'Failed to deposit tokens' });
  }
});

// Get deposit types (helper endpoint)
router.get('/deposit-types', (req, res) => {
  res.json({
    success: true,
    data: {
      0: 'Salary',
      1: 'Bonus',
      2: 'Other'
    }
  });
});

// Get platform stats
router.get('/stats', async (req, res) => {
  try {
    if (!blockchain.contracts.investmentEngine) {
      return res.status(503).json({ error: 'Investment Engine contract not available' });
    }

    const tvlResult = await blockchain.callContract(
      blockchain.contracts.investmentEngine,
      'getTotalValueLocked'
    );

    if (!tvlResult.success) {
      return res.status(500).json({ error: tvlResult.error });
    }

    const blockNumber = await blockchain.getBlockNumber();

    res.json({
      success: true,
      data: {
        totalValueLocked: blockchain.formatTokenAmount(tvlResult.data, 6), // Assuming USDC
        currentBlock: blockNumber,
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Failed to fetch platform stats' });
  }
});

module.exports = router;