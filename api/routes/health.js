const express = require('express');
const router = express.Router();
const blockchain = require('../services/blockchain');

// Health check endpoint
router.get('/', async (req, res) => {
  try {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'development'
    };

    // Check blockchain connection
    try {
      const blockNumber = await blockchain.getBlockNumber();
      health.blockchain = {
        connected: true,
        currentBlock: blockNumber,
        rpcUrl: process.env.RPC_URL || 'http://127.0.0.1:8545'
      };
    } catch (error) {
      health.blockchain = {
        connected: false,
        error: error.message
      };
      health.status = 'degraded';
    }

    // Check contracts
    health.contracts = {
      planManager: !!blockchain.contracts.planManager,
      investmentEngine: !!blockchain.contracts.investmentEngine,
      tokens: {
        usdc: !!blockchain.contracts.tokens.usdc,
        wbtc: !!blockchain.contracts.tokens.wbtc,
        weth: !!blockchain.contracts.tokens.weth
      }
    };

    // Check if any contracts are missing
    const missingContracts = Object.entries(health.contracts)
      .filter(([key, value]) => {
        if (key === 'tokens') {
          return !Object.values(value).some(Boolean);
        }
        return !value;
      });

    if (missingContracts.length > 0) {
      health.status = 'degraded';
      health.warnings = ['Some contracts are not configured'];
    }

    const statusCode = health.status === 'healthy' ? 200 : 503;
    res.status(statusCode).json(health);

  } catch (error) {
    console.error('Health check error:', error);
    res.status(500).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// Detailed system info (for debugging)
router.get('/system', async (req, res) => {
  try {
    const systemInfo = {
      nodeVersion: process.version,
      platform: process.platform,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      environment: {
        NODE_ENV: process.env.NODE_ENV,
        PORT: process.env.PORT,
        RPC_URL: process.env.RPC_URL,
        CHAIN_ID: process.env.CHAIN_ID
      },
      contractAddresses: {
        planManager: process.env.PLAN_MANAGER_ADDRESS,
        investmentEngine: process.env.INVESTMENT_ENGINE_ADDRESS,
        tokens: {
          usdc: process.env.USDC_ADDRESS,
          wbtc: process.env.WBTC_ADDRESS,
          weth: process.env.WETH_ADDRESS
        }
      }
    };

    // Get blockchain info
    try {
      const blockNumber = await blockchain.getBlockNumber();
      const gasPrice = await blockchain.getGasPrice();

      systemInfo.blockchain = {
        blockNumber,
        gasPrice: {
          gasPrice: gasPrice.gasPrice?.toString(),
          maxFeePerGas: gasPrice.maxFeePerGas?.toString(),
          maxPriorityFeePerGas: gasPrice.maxPriorityFeePerGas?.toString()
        }
      };
    } catch (error) {
      systemInfo.blockchain = {
        error: error.message
      };
    }

    res.json({
      success: true,
      data: systemInfo
    });

  } catch (error) {
    console.error('System info error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;