const express = require('express');
const router = express.Router();
const blockchain = require('../services/blockchain');

// Get all supported tokens
router.get('/', (req, res) => {
  const tokens = [];

  if (process.env.USDC_ADDRESS) {
    tokens.push({
      symbol: 'USDC',
      name: 'USD Coin',
      address: process.env.USDC_ADDRESS,
      decimals: 6,
      type: 'stablecoin'
    });
  }

  if (process.env.WBTC_ADDRESS) {
    tokens.push({
      symbol: 'WBTC',
      name: 'Wrapped Bitcoin',
      address: process.env.WBTC_ADDRESS,
      decimals: 8,
      type: 'crypto'
    });
  }

  if (process.env.WETH_ADDRESS) {
    tokens.push({
      symbol: 'WETH',
      name: 'Wrapped Ether',
      address: process.env.WETH_ADDRESS,
      decimals: 18,
      type: 'crypto'
    });
  }

  res.json({
    success: true,
    data: tokens,
    total: tokens.length
  });
});

// Get token info
router.get('/:tokenAddress', async (req, res) => {
  try {
    const { tokenAddress } = req.params;

    // Find token contract
    let tokenContract = null;
    for (const contract of Object.values(blockchain.contracts.tokens)) {
      if (contract.target.toLowerCase() === tokenAddress.toLowerCase()) {
        tokenContract = contract;
        break;
      }
    }

    if (!tokenContract) {
      return res.status(404).json({ error: 'Token not found or not supported' });
    }

    // Get token info
    const nameResult = await blockchain.callContract(tokenContract, 'name');
    const symbolResult = await blockchain.callContract(tokenContract, 'symbol');
    const decimalsResult = await blockchain.callContract(tokenContract, 'decimals');

    if (!nameResult.success || !symbolResult.success || !decimalsResult.success) {
      return res.status(500).json({ error: 'Failed to fetch token information' });
    }

    res.json({
      success: true,
      data: {
        address: tokenAddress,
        name: nameResult.data,
        symbol: symbolResult.data,
        decimals: parseInt(decimalsResult.data)
      }
    });

  } catch (error) {
    console.error('Error fetching token info:', error);
    res.status(500).json({ error: 'Failed to fetch token information' });
  }
});

// Get token balance for user
router.get('/:tokenAddress/balance/:userAddress', async (req, res) => {
  try {
    const { tokenAddress, userAddress } = req.params;

    // Find token contract
    let tokenContract = null;
    for (const contract of Object.values(blockchain.contracts.tokens)) {
      if (contract.target.toLowerCase() === tokenAddress.toLowerCase()) {
        tokenContract = contract;
        break;
      }
    }

    if (!tokenContract) {
      return res.status(404).json({ error: 'Token not found or not supported' });
    }

    // Get balance
    const balanceResult = await blockchain.callContract(tokenContract, 'balanceOf', [userAddress]);
    const decimalsResult = await blockchain.callContract(tokenContract, 'decimals');
    const symbolResult = await blockchain.callContract(tokenContract, 'symbol');

    if (!balanceResult.success || !decimalsResult.success || !symbolResult.success) {
      return res.status(500).json({ error: 'Failed to fetch token balance' });
    }

    const decimals = parseInt(decimalsResult.data);

    res.json({
      success: true,
      data: {
        tokenAddress,
        userAddress,
        symbol: symbolResult.data,
        balance: blockchain.formatTokenAmount(balanceResult.data, decimals),
        rawBalance: balanceResult.data.toString(),
        decimals
      }
    });

  } catch (error) {
    console.error('Error fetching token balance:', error);
    res.status(500).json({ error: 'Failed to fetch token balance' });
  }
});

// Get allowance for Investment Engine
router.get('/:tokenAddress/allowance/:userAddress', async (req, res) => {
  try {
    const { tokenAddress, userAddress } = req.params;

    if (!process.env.INVESTMENT_ENGINE_ADDRESS) {
      return res.status(503).json({ error: 'Investment Engine address not configured' });
    }

    // Find token contract
    let tokenContract = null;
    for (const contract of Object.values(blockchain.contracts.tokens)) {
      if (contract.target.toLowerCase() === tokenAddress.toLowerCase()) {
        tokenContract = contract;
        break;
      }
    }

    if (!tokenContract) {
      return res.status(404).json({ error: 'Token not found or not supported' });
    }

    // Get allowance
    const allowanceResult = await blockchain.callContract(
      tokenContract,
      'allowance',
      [userAddress, process.env.INVESTMENT_ENGINE_ADDRESS]
    );
    const decimalsResult = await blockchain.callContract(tokenContract, 'decimals');
    const symbolResult = await blockchain.callContract(tokenContract, 'symbol');

    if (!allowanceResult.success || !decimalsResult.success || !symbolResult.success) {
      return res.status(500).json({ error: 'Failed to fetch token allowance' });
    }

    const decimals = parseInt(decimalsResult.data);

    res.json({
      success: true,
      data: {
        tokenAddress,
        userAddress,
        spender: process.env.INVESTMENT_ENGINE_ADDRESS,
        symbol: symbolResult.data,
        allowance: blockchain.formatTokenAmount(allowanceResult.data, decimals),
        rawAllowance: allowanceResult.data.toString(),
        decimals
      }
    });

  } catch (error) {
    console.error('Error fetching token allowance:', error);
    res.status(500).json({ error: 'Failed to fetch token allowance' });
  }
});

module.exports = router;