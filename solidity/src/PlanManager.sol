// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IPlanManager.sol";

contract PlanManager is IPlanManager {
    // State variables
    uint256 private _planCounter;
    address public owner;

    // Asset class risk factors (1-10 scale)
    mapping(AssetClass => uint256) public assetRiskFactors;

    // Storage mappings
    mapping(uint256 => InvestmentPlan) private _plans;
    mapping(uint256 => AssetAllocation[]) private _planAllocations;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier planExists(uint256 planId) {
        require(planId > 0 && planId <= _planCounter, "Plan does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;

        // Initialize asset risk factors
        assetRiskFactors[AssetClass.Stablecoin] = 1;
        assetRiskFactors[AssetClass.RWA] = 4;
        assetRiskFactors[AssetClass.Crypto] = 7;
        assetRiskFactors[AssetClass.Liquidity] = 6;
    }

    // Plan Management Functions
    function createPlan(
        PlanType planType,
        string memory name,
        AssetAllocation[] memory allocations
    ) external onlyOwner returns (uint256 planId) {
        require(bytes(name).length > 0, "Plan name cannot be empty");
        require(
            allocations.length > 0,
            "Plan must have at least one allocation"
        );
        require(validateAllocation(allocations), "Invalid allocation");

        _planCounter++;
        planId = _planCounter;

        // Calculate risk score from allocations
        uint256 riskScore = calculateRiskScore(allocations);

        // Create plan
        _plans[planId] = InvestmentPlan({
            planId: planId,
            planType: planType,
            name: name,
            allocations: new AssetAllocation[](0), // Will be set below
            riskScore: riskScore,
            isActive: true,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        // Store allocations separately due to dynamic array limitations
        delete _planAllocations[planId];
        for (uint256 i = 0; i < allocations.length; i++) {
            _planAllocations[planId].push(allocations[i]);
        }

        emit PlanCreated(planId, planType, name);

        return planId;
    }

    function updatePlan(
        uint256 planId,
        AssetAllocation[] memory allocations
    ) external onlyOwner planExists(planId) {
        require(
            allocations.length > 0,
            "Plan must have at least one allocation"
        );
        require(validateAllocation(allocations), "Invalid allocation");

        // Recalculate risk score
        uint256 newRiskScore = calculateRiskScore(allocations);

        // Update plan
        _plans[planId].riskScore = newRiskScore;
        _plans[planId].updatedAt = block.timestamp;

        // Update allocations
        delete _planAllocations[planId];
        for (uint256 i = 0; i < allocations.length; i++) {
            _planAllocations[planId].push(allocations[i]);
        }

        emit PlanUpdated(planId);
    }

    // View Functions
    function getPlan(
        uint256 planId
    ) external view planExists(planId) returns (InvestmentPlan memory) {
        InvestmentPlan memory plan = _plans[planId];

        // Copy allocations from separate storage
        AssetAllocation[] memory allocations = new AssetAllocation[](
            _planAllocations[planId].length
        );
        for (uint256 i = 0; i < _planAllocations[planId].length; i++) {
            allocations[i] = _planAllocations[planId][i];
        }
        plan.allocations = allocations;

        return plan;
    }

    function getAllPlans() external view returns (InvestmentPlan[] memory) {
        InvestmentPlan[] memory plans = new InvestmentPlan[](_planCounter);

        for (uint256 i = 1; i <= _planCounter; i++) {
            plans[i - 1] = this.getPlan(i);
        }

        return plans;
    }

    function getActivePlans() external view returns (InvestmentPlan[] memory) {
        // Count active plans first
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= _planCounter; i++) {
            if (_plans[i].isActive) {
                activeCount++;
            }
        }

        InvestmentPlan[] memory activePlans = new InvestmentPlan[](activeCount);
        uint256 index = 0;

        for (uint256 i = 1; i <= _planCounter; i++) {
            if (_plans[i].isActive) {
                activePlans[index] = this.getPlan(i);
                index++;
            }
        }

        return activePlans;
    }

    function getTotalPlans() external view returns (uint256) {
        return _planCounter;
    }

    function getAssetAllocationLimits(
        uint256 planId
    ) external view planExists(planId) returns (AssetAllocation[] memory) {
        AssetAllocation[] memory allocations = new AssetAllocation[](
            _planAllocations[planId].length
        );
        for (uint256 i = 0; i < _planAllocations[planId].length; i++) {
            allocations[i] = _planAllocations[planId][i];
        }
        return allocations;
    }

    // Validation Functions
    function validateAllocation(
        AssetAllocation[] memory allocations
    ) public pure returns (bool) {
        uint256 totalPercentage = 0;

        for (uint256 i = 0; i < allocations.length; i++) {
            AssetAllocation memory allocation = allocations[i];

            // Check percentage bounds
            require(
                allocation.targetPercentage > 0,
                "Target percentage must be greater than 0"
            );
            require(
                allocation.targetPercentage <= 10000,
                "Target percentage cannot exceed 100%"
            );
            require(
                allocation.minPercentage <= allocation.targetPercentage,
                "Min percentage cannot exceed target"
            );
            require(
                allocation.maxPercentage >= allocation.targetPercentage,
                "Max percentage cannot be less than target"
            );
            require(
                allocation.maxPercentage <= 10000,
                "Max percentage cannot exceed 100%"
            );
            require(
                allocation.tokenAddress != address(0),
                "Token address cannot be zero"
            );

            totalPercentage += allocation.targetPercentage;
        }

        // Total allocation must equal 100% (10000 basis points)
        require(totalPercentage == 10000, "Total allocation must equal 100%");

        return true;
    }

    function calculateRiskScore(
        AssetAllocation[] memory allocations
    ) public view returns (uint256) {
        require(allocations.length > 0, "No allocations provided");

        uint256 weightedRiskSum = 0;
        uint256 totalWeight = 0;

        for (uint256 i = 0; i < allocations.length; i++) {
            uint256 assetRisk = assetRiskFactors[allocations[i].assetClass];
            uint256 weight = allocations[i].targetPercentage;

            weightedRiskSum += (assetRisk * weight);
            totalWeight += weight;
        }

        require(totalWeight > 0, "Total weight must be greater than 0");

        // Calculate weighted average and scale to 1-10
        uint256 riskScore = (weightedRiskSum * 10) / (totalWeight * 10);

        // Ensure risk score is between 1 and 10
        if (riskScore == 0) riskScore = 1;
        if (riskScore > 10) riskScore = 10;

        return riskScore;
    }

    // Administrative Functions
    function setAssetRiskFactor(
        AssetClass assetClass,
        uint256 riskFactor
    ) external onlyOwner {
        require(
            riskFactor >= 1 && riskFactor <= 10,
            "Risk factor must be between 1 and 10"
        );
        assetRiskFactors[assetClass] = riskFactor;
    }
}
