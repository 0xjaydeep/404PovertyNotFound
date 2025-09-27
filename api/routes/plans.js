const express = require('express');
const router = express.Router();
const { ethers } = require('ethers');

// Import configuration and validation
const {
  initializeProvider,
  createPlanManagerContract,
} = require('../config/contracts');

const {
  validatePlanId,
} = require('../middleware/validation');

// Initialize provider and contracts
const provider = initializeProvider();
const planManager = createPlanManagerContract(provider);

/**
 * @route GET /api/plans
 * @desc Get all available investment plans
 * @access Public
 */
router.get('/', async (req, res) => {
  try {
    const totalPlans = await planManager.getTotalPlans();
    const plans = [];

    for (let i = 1; i <= totalPlans; i++) {
      const plan = await planManager.getPlan(i);
      plans.push({
        planId: plan.planId.toString(),
        planType: plan.planType.toString(),
        name: plan.name,
        allocations: plan.allocations.map(allocation => ({
          assetClass: allocation.assetClass.toString(),
          tokenAddress: allocation.tokenAddress,
          targetPercentage: allocation.targetPercentage.toString(),
          minPercentage: allocation.minPercentage.toString(),
          maxPercentage: allocation.maxPercentage.toString()
        })),
        riskScore: plan.riskScore.toString(),
        isActive: plan.isActive,
        createdAt: plan.createdAt.toString(),
        updatedAt: plan.updatedAt.toString()
      });
    }

    res.json({
      success: true,
      data: {
        totalPlans: totalPlans.toString(),
        plans
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route GET /api/plans/:planId
 * @desc Get specific investment plan details
 * @access Public
 */
router.get('/:planId', validatePlanId, async (req, res) => {
  try {
    const { planId } = req.params;
    const plan = await planManager.getPlan(planId);

    if (!plan.isActive) {
      return res.status(404).json({
        success: false,
        error: 'Plan not found or inactive'
      });
    }

    res.json({
      success: true,
      data: {
        planId: plan.planId.toString(),
        planType: plan.planType.toString(),
        name: plan.name,
        allocations: plan.allocations.map(allocation => ({
          assetClass: allocation.assetClass.toString(),
          tokenAddress: allocation.tokenAddress,
          targetPercentage: allocation.targetPercentage.toString(),
          minPercentage: allocation.minPercentage.toString(),
          maxPercentage: allocation.maxPercentage.toString()
        })),
        riskScore: plan.riskScore.toString(),
        isActive: plan.isActive,
        createdAt: plan.createdAt.toString(),
        updatedAt: plan.updatedAt.toString()
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route POST /api/plans
 * @desc Create a new investment plan
 * @access Private (requires admin wallet)
 */
router.post('/', async (req, res) => {
    try {
        const { planType, name, allocations } = req.body;

        if (planType === undefined || !name || !allocations || !Array.isArray(allocations)) {
            return res.status(400).json({ success: false, error: 'Missing required fields: planType, name, allocations' });
        }

        const formattedAllocations = allocations.map(alloc => ({
            assetClass: alloc.assetClass,
            tokenAddress: alloc.tokenAddress,
            targetPercentage: alloc.targetPercentage,
            minPercentage: alloc.minPercentage,
            maxPercentage: alloc.maxPercentage,
        }));

        // Note: This requires the admin wallet to have funds to pay for gas.
        const adminWallet = new ethers.Wallet(process.env.ADMIN_PRIVATE_KEY, provider);
        const planManagerWithSigner = planManager.connect(adminWallet);

        const tx = await planManagerWithSigner.createPlan(planType, name, formattedAllocations);
        const receipt = await tx.wait();

        res.status(201).json({
            success: true,
            message: 'Investment plan created successfully',
            transactionHash: receipt.transactionHash,
            planId: receipt.events?.find(e => e.event === 'PlanCreated')?.args?.planId.toString()
        });

    } catch (error) {
        console.error('Error creating plan:', error);
        res.status(500).json({ success: false, error: 'Failed to create investment plan' });
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