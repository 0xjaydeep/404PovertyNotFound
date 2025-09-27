const express = require('express');
const router = express.Router();
const blockchain = require('../services/blockchain');

// Get all investment plans
router.get('/', async (req, res) => {
  try {
    if (!blockchain.contracts.planManager) {
      return res.status(503).json({ error: 'Plan Manager contract not available' });
    }

    // First get total number of plans
    const totalResult = await blockchain.callContract(
      blockchain.contracts.planManager,
      'getTotalPlans'
    );

    if (!totalResult.success) {
      return res.status(500).json({ error: totalResult.error });
    }

    const totalPlans = parseInt(totalResult.data);
    const plans = [];

    // Fetch each plan individually
    for (let i = 1; i <= totalPlans; i++) {
      const planResult = await blockchain.callContract(
        blockchain.contracts.planManager,
        'getPlan',
        [i]
      );

      if (planResult.success) {
        const plan = planResult.data;
        plans.push({
          planId: plan.planId.toString(),
          planType: parseInt(plan.planType),
          name: plan.name,
          isActive: plan.isActive,
          createdAt: new Date(parseInt(plan.createdAt) * 1000).toISOString(),
          updatedAt: new Date(parseInt(plan.updatedAt) * 1000).toISOString(),
          riskScore: parseInt(plan.riskScore),
          allocations: plan.allocations.map(allocation => ({
            assetClass: parseInt(allocation.assetClass),
            tokenAddress: allocation.tokenAddress,
            targetPercentage: parseInt(allocation.targetPercentage) / 100, // Convert to percentage
            minPercentage: parseInt(allocation.minPercentage) / 100,
            maxPercentage: parseInt(allocation.maxPercentage) / 100
          }))
        });
      }
    }

    res.json({
      success: true,
      data: plans,
      total: plans.length
    });

  } catch (error) {
    console.error('Error fetching plans:', error);
    res.status(500).json({ error: 'Failed to fetch investment plans' });
  }
});

// Get specific plan by ID
router.get('/:planId', async (req, res) => {
  try {
    const { planId } = req.params;

    if (!blockchain.contracts.planManager) {
      return res.status(503).json({ error: 'Plan Manager contract not available' });
    }

    const result = await blockchain.callContract(
      blockchain.contracts.planManager,
      'getPlan',
      [planId]
    );

    if (!result.success) {
      return res.status(500).json({ error: result.error });
    }

    const plan = result.data;

    res.json({
      success: true,
      data: {
        planId: plan.planId.toString(),
        planType: parseInt(plan.planType),
        name: plan.name,
        isActive: plan.isActive,
        createdAt: new Date(parseInt(plan.createdAt) * 1000).toISOString(),
        allocations: plan.allocations.map(allocation => ({
          assetClass: parseInt(allocation.assetClass),
          tokenAddress: allocation.tokenAddress,
          targetPercentage: parseInt(allocation.targetPercentage) / 100,
          minPercentage: parseInt(allocation.minPercentage) / 100,
          maxPercentage: parseInt(allocation.maxPercentage) / 100
        }))
      }
    });

  } catch (error) {
    console.error('Error fetching plan:', error);
    res.status(500).json({ error: 'Failed to fetch investment plan' });
  }
});

// Create new investment plan
router.post('/', async (req, res) => {
  try {
    const { planType, name, allocations } = req.body;

    // Validate input
    if (!planType || !name || !allocations || !Array.isArray(allocations)) {
      return res.status(400).json({ error: 'Missing required fields: planType, name, allocations' });
    }

    if (!blockchain.contracts.planManager) {
      return res.status(503).json({ error: 'Plan Manager contract not available' });
    }

    // Format allocations for contract
    const formattedAllocations = allocations.map(allocation => ({
      assetClass: allocation.assetClass,
      tokenAddress: allocation.tokenAddress,
      targetPercentage: Math.floor(allocation.targetPercentage * 100), // Convert percentage to basis points
      minPercentage: Math.floor(allocation.minPercentage * 100),
      maxPercentage: Math.floor(allocation.maxPercentage * 100)
    }));

    const result = await blockchain.executeTransaction(
      blockchain.contracts.planManager,
      'createPlan',
      [planType, name, formattedAllocations]
    );

    if (!result.success) {
      return res.status(500).json({ error: result.error });
    }

    res.status(201).json({
      success: true,
      message: 'Investment plan created successfully',
      transactionHash: result.txHash,
      blockNumber: result.blockNumber
    });

  } catch (error) {
    console.error('Error creating plan:', error);
    res.status(500).json({ error: 'Failed to create investment plan' });
  }
});

// Get plan types (helper endpoint)
router.get('/types/list', (req, res) => {
  res.json({
    success: true,
    data: {
      0: 'Conservative',
      1: 'Balanced',
      2: 'Aggressive',
      3: 'Target Date'
    }
  });
});

// Get asset classes (helper endpoint)
router.get('/assets/classes', (req, res) => {
  res.json({
    success: true,
    data: {
      0: 'Crypto',
      1: 'RWA',
      2: 'Liquidity',
      3: 'Stablecoin'
    }
  });
});

module.exports = router;