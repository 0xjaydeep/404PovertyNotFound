// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IPlanManager.sol";

interface IInvestmentEngine {
    enum DepositType {
        Manual,
        Salary,
        EmployerMatch
    }

    enum InvestmentStatus {
        Pending,
        Executed,
        Failed
    }

    struct UserDeposit {
        address user;
        uint256 amount;
        DepositType depositType;
        uint256 timestamp;
        bool processed;
    }

    struct Investment {
        uint256 investmentId;
        address user;
        uint256 planId;
        uint256 totalAmount;
        InvestmentStatus status;
        uint256 executedAmount;
        uint256 timestamp;
        uint256 executedAt;
    }

    struct UserBalance {
        address user;
        uint256 totalDeposited;
        uint256 totalInvested;
        uint256 pendingInvestment;
        uint256 availableBalance;
    }

    // Events
    event DepositReceived(
        address indexed user,
        uint256 amount,
        DepositType depositType
    );
    event InvestmentExecuted(
        uint256 indexed investmentId,
        address indexed user,
        uint256 amount
    );
    event InvestmentFailed(
        uint256 indexed investmentId,
        address indexed user,
        string reason
    );

    // Deposit Functions
    function deposit(uint256 amount, DepositType depositType) external;

    function depositForUser(
        address user,
        uint256 amount,
        DepositType depositType
    ) external;

    function batchDeposit(
        address[] memory users,
        uint256[] memory amounts,
        DepositType depositType
    ) external;

    // Investment Functions
    function invest(
        uint256 planId,
        uint256 amount
    ) external returns (uint256 investmentId);

    function executeInvestment(uint256 investmentId) external;

    function batchExecuteInvestments(uint256[] memory investmentIds) external;

    // Rebalancing Functions
    function rebalance(address user, uint256 planId) external;

    // View Functions
    function getUserBalance(
        address user
    ) external view returns (UserBalance memory);

    function getUserDeposits(
        address user
    ) external view returns (UserDeposit[] memory);

    function getUserInvestments(
        address user
    ) external view returns (Investment[] memory);

    function getInvestment(
        uint256 investmentId
    ) external view returns (Investment memory);

    function getPendingInvestments(
        address user
    ) external view returns (Investment[] memory);

    function getTotalValueLocked() external view returns (uint256);

    function getUserPortfolioValue(
        address user
    ) external view returns (uint256);
}
