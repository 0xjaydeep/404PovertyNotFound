// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IInvestmentEngine.sol";
import "./interfaces/IPlanManager.sol";

// PyUSD Manager Interface
interface IPyUSDManager {
    function convertETHToPyUSD(
        address user,
        uint256 investmentId,
        uint256 ethAmount,
        address destination
    ) external payable returns (uint256 pyusdReceived);
    
    function transferPyUSD(
        address user,
        uint256 investmentId,
        uint256 amount,
        address destination
    ) external;
    
    function getConversionQuote(uint256 ethAmount) 
        external 
        view 
        returns (uint256 expectedPyUSD, uint256 minPyUSDOut);
    
    function getPyUSDBalance() external view returns (uint256);
    function getUserPyUSDAllocation(address user) external view returns (uint256);
    function getInvestmentPyUSDAmount(uint256 investmentId) external view returns (uint256);
    function isInitialized() external view returns (bool);
}

contract InvestmentEngine is IInvestmentEngine {
    // State variables
    uint256 private _depositCounter;
    uint256 private _investmentCounter;
    address public owner;
    address public planManager;
    uint256 public minimumDeposit;

    IPyUSDManager public pyusdManager;

    // Storage mappings
    mapping(uint256 => UserDeposit) private _deposits;
    mapping(address => uint256[]) private _userDeposits;
    mapping(uint256 => Investment) private _investments;
    mapping(address => uint256[]) private _userInvestments;
    mapping(address => UserBalance) private _userBalances;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier depositExists(uint256 depositId) {
        require(
            depositId > 0 && depositId <= _depositCounter,
            "Deposit does not exist"
        );
        _;
    }

    modifier investmentExists(uint256 investmentId) {
        require(
            investmentId > 0 && investmentId <= _investmentCounter,
            "Investment does not exist"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
        minimumDeposit = 100; // 100 wei minimum deposit
    }

    // Set PyUSD Manager
    function setPyUSDManager(address _pyusdManager) external onlyOwner {
        require(_pyusdManager != address(0), "Invalid PyUSD manager address");
        pyusdManager = IPyUSDManager(_pyusdManager);
    }

    // Deposit Functions
    function deposit(uint256 amount, DepositType depositType) external {
        require(amount >= minimumDeposit, "Amount below minimum deposit");
        _processDeposit(msg.sender, amount, depositType);
    }

    function depositForUser(
        address user,
        uint256 amount,
        DepositType depositType
    ) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount >= minimumDeposit, "Amount below minimum deposit");
        _processDeposit(user, amount, depositType);
    }

    function batchDeposit(
        address[] memory users,
        uint256[] memory amounts,
        DepositType depositType
    ) external onlyOwner {
        require(users.length == amounts.length, "Arrays length mismatch");
        require(users.length > 0, "Empty arrays");

        for (uint256 i = 0; i < users.length; i++) {
            require(users[i] != address(0), "Invalid user address");
            require(
                amounts[i] >= minimumDeposit,
                "Amount below minimum deposit"
            );
            _processDeposit(users[i], amounts[i], depositType);
        }
    }

    // Investment Functions
    function invest(
        uint256 planId,
        uint256 amount
    ) external returns (uint256 investmentId) {
        require(amount > 0, "Investment amount must be greater than 0");
        require(
            _userBalances[msg.sender].availableBalance >= amount,
            "Insufficient balance"
        );

        _investmentCounter++;
        investmentId = _investmentCounter;

        // Create investment record
        _investments[investmentId] = Investment({
            investmentId: investmentId,
            user: msg.sender,
            planId: planId,
            totalAmount: amount,
            status: InvestmentStatus.Pending,
            executedAmount: 0,
            timestamp: block.timestamp,
            executedAt: 0
        });

        // Update user balance
        _userBalances[msg.sender].availableBalance -= amount;
        _userBalances[msg.sender].pendingInvestment += amount;

        // Track user investments
        _userInvestments[msg.sender].push(investmentId);

        return investmentId;
    }

    function executeInvestment(
        uint256 investmentId
    ) external onlyOwner investmentExists(investmentId) {
        Investment storage investment = _investments[investmentId];
        require(
            investment.status == InvestmentStatus.Pending,
            "Investment not pending"
        );

        // Check if PyUSD integration is available and active
        if (_shouldUsePyUSDIntegration()) {
            _executeInvestmentWithPyUSD(investment);
        } else {
            // Original logic for backward compatibility
            _executeInvestmentOriginal(investment);
        }

        emit InvestmentExecuted(investmentId, investment.user, investment.totalAmount);
    }

    // NEW: Check if PyUSD integration should be used
    function _shouldUsePyUSDIntegration() internal view returns (bool) {
        return address(pyusdManager) != address(0) && 
               pyusdManager.isInitialized() && 
               planManager != address(0);
    }

    // NEW: Enhanced execution with modular PyUSD support
    function _executeInvestmentWithPyUSD(Investment storage investment) internal {
        // Get investment plan allocations
        try IPlanManager(planManager).getAssetAllocationLimits(investment.planId) 
            returns (AssetAllocation[] memory allocations) {
            
            uint256 totalExecutedAmount = 0;
            
            for (uint256 i = 0; i < allocations.length; i++) {
                AssetAllocation memory allocation = allocations[i];
                uint256 allocationAmount = (investment.totalAmount * allocation.targetPercentage) / 10000;
                
                if (allocation.assetClass == AssetClass.Stablecoin && allocationAmount > 0) {
                    // CRITICAL CALL: Delegate PyUSD conversion to PyUSDManager
                    try pyusdManager.convertETHToPyUSD{value: allocationAmount}(
                        investment.user,
                        investment.investmentId,
                        allocationAmount,
                        allocation.tokenAddress // destination (address(0) keeps in PyUSDManager)
                    ) returns (uint256 pyusdReceived) {
                        // PyUSD conversion successful
                        // PyUSDManager handles all tracking internally
                    } catch {
                        // If PyUSD conversion fails, continue with original logic
                        // This ensures no investment execution fails due to PyUSD issues
                    }
                }
                // Handle other asset classes here (Crypto, RWA, Liquidity)
                // This is where you'd implement other investment logic
                
                totalExecutedAmount += allocationAmount;
            }
            
            // Update investment status
            investment.status = InvestmentStatus.Executed;
            investment.executedAmount = totalExecutedAmount;
            investment.executedAt = block.timestamp;

            // Update user balance
            _userBalances[investment.user].pendingInvestment -= investment.totalAmount;
            _userBalances[investment.user].totalInvested += totalExecutedAmount;
            
        } catch {
            // Fallback to original execution if anything fails
            _executeInvestmentOriginal(investment);
        }
    }

    // Original execution logic (preserved for backward compatibility)
    function _executeInvestmentOriginal(Investment storage investment) internal {
        // Update investment status
        investment.status = InvestmentStatus.Executed;
        investment.executedAmount = investment.totalAmount;
        investment.executedAt = block.timestamp;

        // Update user balance
        address user = investment.user;
        _userBalances[user].pendingInvestment -= investment.totalAmount;
        _userBalances[user].totalInvested += investment.totalAmount;
    }

    function batchExecuteInvestments(
        uint256[] memory investmentIds
    ) external onlyOwner {
        require(investmentIds.length > 0, "Empty investment IDs array");

        for (uint256 i = 0; i < investmentIds.length; i++) {
            uint256 investmentId = investmentIds[i];
            
            if (investmentId > 0 && investmentId <= _investmentCounter) {
                Investment storage investment = _investments[investmentId];

                if (investment.status == InvestmentStatus.Pending) {
                    // Use the same executeInvestment logic
                    if (_shouldUsePyUSDIntegration()) {
                        _executeInvestmentWithPyUSD(investment);
                    } else {
                        _executeInvestmentOriginal(investment);
                    }

                    emit InvestmentExecuted(
                        investmentId,
                        investment.user,
                        investment.totalAmount
                    );
                }
            }
        }
    }

    // Rebalancing Functions
    function rebalance(address user, uint256 planId) external onlyOwner {
        require(user != address(0), "Invalid user address");

        // Simple rebalancing logic - in a real implementation, this would
        // interact with DEXs and asset protocols to rebalance according to plan allocations
        uint256 portfolioValue = this.getUserPortfolioValue(user);

        // For now, just emit an event to indicate rebalancing occurred
        // In full implementation, this would:
        // 1. Get plan allocations from PlanManager
        // 2. Calculate current asset distribution
        // 3. Execute trades to match target allocations

        // Placeholder implementation
        require(portfolioValue > 0, "No portfolio to rebalance");
    }

    // View Functions
    function getUserBalance(
        address user
    ) external view returns (UserBalance memory) {
        return _userBalances[user];
    }

    function getUserDeposits(
        address user
    ) external view returns (UserDeposit[] memory) {
        uint256[] memory depositIds = _userDeposits[user];
        UserDeposit[] memory deposits = new UserDeposit[](depositIds.length);

        for (uint256 i = 0; i < depositIds.length; i++) {
            deposits[i] = _deposits[depositIds[i]];
        }

        return deposits;
    }

    function getUserInvestments(
        address user
    ) external view returns (Investment[] memory) {
        uint256[] memory investmentIds = _userInvestments[user];
        Investment[] memory investments = new Investment[](
            investmentIds.length
        );

        for (uint256 i = 0; i < investmentIds.length; i++) {
            investments[i] = _investments[investmentIds[i]];
        }

        return investments;
    }

    function getInvestment(
        uint256 investmentId
    ) external view investmentExists(investmentId) returns (Investment memory) {
        return _investments[investmentId];
    }

    function getPendingInvestments(
        address user
    ) external view returns (Investment[] memory) {
        uint256[] memory investmentIds = _userInvestments[user];

        // Count pending investments
        uint256 pendingCount = 0;
        for (uint256 i = 0; i < investmentIds.length; i++) {
            if (
                _investments[investmentIds[i]].status ==
                InvestmentStatus.Pending
            ) {
                pendingCount++;
            }
        }

        // Create array of pending investments
        Investment[] memory pendingInvestments = new Investment[](pendingCount);
        uint256 index = 0;

        for (uint256 i = 0; i < investmentIds.length; i++) {
            if (
                _investments[investmentIds[i]].status ==
                InvestmentStatus.Pending
            ) {
                pendingInvestments[index] = _investments[investmentIds[i]];
                index++;
            }
        }

        return pendingInvestments;
    }

    function getTotalValueLocked() external view returns (uint256) {
        // In a real implementation, this would aggregate all user balances
        // For simplicity, returning 0 for now
        return 0;
    }

    function getUserPortfolioValue(
        address user
    ) external view returns (uint256) {
        UserBalance memory balance = _userBalances[user];
        return
            balance.totalInvested +
            balance.pendingInvestment +
            balance.availableBalance;
    }

    // Internal helper functions
    function _processDeposit(
        address user,
        uint256 amount,
        DepositType depositType
    ) internal {
        _depositCounter++;
        uint256 depositId = _depositCounter;

        // Create deposit record
        _deposits[depositId] = UserDeposit({
            user: user,
            amount: amount,
            depositType: depositType,
            timestamp: block.timestamp,
            processed: true
        });

        // Update user balance
        _userBalances[user].totalDeposited += amount;
        _userBalances[user].availableBalance += amount;

        // Track user deposits
        _userDeposits[user].push(depositId);

        emit DepositReceived(user, amount, depositType);
    }

    // Administrative Functions
    function setPlanManager(address _planManager) external onlyOwner {
        require(_planManager != address(0), "Invalid plan manager address");
        planManager = _planManager;
    }

    function setMinimumDeposit(uint256 amount) external onlyOwner {
        minimumDeposit = amount;
    }

    // NEW: PyUSD-specific view functions (delegate to PyUSDManager)
    function getPyUSDBalance() external view returns (uint256) {
        if (address(pyusdManager) == address(0)) return 0;
        return pyusdManager.getPyUSDBalance();
    }
    
    function getUserPyUSDAllocation(address user) external view returns (uint256) {
        if (address(pyusdManager) == address(0)) return 0;
        return pyusdManager.getUserPyUSDAllocation(user);
    }

    function getInvestmentPyUSDAmount(uint256 investmentId) external view returns (uint256) {
        if (address(pyusdManager) == address(0)) return 0;
        return pyusdManager.getInvestmentPyUSDAmount(investmentId);
    }

    function isPyUSDEnabled() external view returns (bool) {
        return _shouldUsePyUSDIntegration();
    }

    // NEW: Get PyUSD conversion quote (delegate to PyUSDManager)
    function getPyUSDConversionQuote(uint256 ethAmount) 
        external 
        view 
        returns (uint256 expectedPyUSD, uint256 minPyUSDOut) 
    {
        if (address(pyusdManager) == address(0)) {
            return (0, 0);
        }

        return pyusdManager.getConversionQuote(ethAmount);
    }

    // Receive ETH function for deposits and swaps
    receive() external payable {
        // Allow contract to receive ETH
    }
}