// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPlanManager {
    enum PlanType {
        Conservative,
        Balanced,
        Aggressive,
        Custom
    }

    enum AssetClass {
        Crypto,
        RWA,
        Liquidity,
        Stablecoin
    }

    struct AssetAllocation {
        AssetClass assetClass;
        address tokenAddress;
        uint256 targetPercentage; // Basis points (e.g., 2500 = 25%)
        uint256 minPercentage;
        uint256 maxPercentage;
    }

    struct InvestmentPlan {
        uint256 planId;
        PlanType planType;
        string name;
        AssetAllocation[] allocations;
        uint256 riskScore; // 1-10 scale
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }

    // Events
    event PlanCreated(uint256 indexed planId, PlanType planType, string name);
    event PlanUpdated(uint256 indexed planId);

    // Plan Management Functions
    function createPlan(
        PlanType planType,
        string memory name,
        AssetAllocation[] memory allocations
    ) external returns (uint256 planId);

    function updatePlan(
        uint256 planId,
        AssetAllocation[] memory allocations
    ) external;

    function getPlan(
        uint256 planId
    ) external view returns (InvestmentPlan memory);

    function getAllPlans() external view returns (InvestmentPlan[] memory);

    function getActivePlans() external view returns (InvestmentPlan[] memory);

    // Validation Functions
    function validateAllocation(
        AssetAllocation[] memory allocations
    ) external pure returns (bool);

    function calculateRiskScore(
        AssetAllocation[] memory allocations
    ) external view returns (uint256);

    // View Functions
    function getTotalPlans() external view returns (uint256);

    function getAssetAllocationLimits(
        uint256 planId
    ) external view returns (AssetAllocation[] memory);

    // Administrative Functions
    function setAssetRiskFactor(
        AssetClass assetClass,
        uint256 riskFactor
    ) external;
}
