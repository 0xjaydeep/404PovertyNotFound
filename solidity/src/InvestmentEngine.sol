// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IInvestmentEngine.sol";
import "./interfaces/IPlanManager.sol";
import "./interfaces/IPriceOracle.sol";

/**
 * @title InvestmentEngineV2
 * @notice Enhanced Investment Engine with Oracle integration for live price-based portfolio calculations
 */
contract InvestmentEngineV2 is IInvestmentEngine {
    // State variables
    uint256 private _depositCounter;
    uint256 private _investmentCounter;
    address public owner;
    address public planManager;
    address public priceOracle;
    uint256 public minimumDeposit;

    // Price staleness threshold (default: 5 minutes)
    uint256 public priceStalenessTreshold = 300;

    // Rebalancing threshold (basis points, 500 = 5%)
    uint256 public rebalanceThreshold = 500;

    // Storage mappings
    mapping(uint256 => UserDeposit) private _deposits;
    mapping(address => uint256[]) private _userDeposits;
    mapping(uint256 => Investment) private _investments;
    mapping(address => uint256[]) private _userInvestments;
    mapping(address => UserBalance) private _userBalances;

    // Portfolio tracking
    mapping(address => mapping(IPriceOracle.AssetClass => uint256))
        private _userAssetBalances;
    mapping(address => uint256) private _lastRebalanceTime;

    // Events
    event OracleUpdated(address indexed newOracle);
    event PortfolioRebalanced(
        address indexed user,
        uint256 totalValue,
        uint256 timestamp
    );
    event AssetAllocationUpdated(
        address indexed user,
        IPriceOracle.AssetClass assetClass,
        uint256 amount
    );
    event PriceBasedInvestmentExecuted(
        uint256 indexed investmentId,
        uint256 usdValue,
        int64 price
    );

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

    modifier oracleConfigured() {
        require(priceOracle != address(0), "Price oracle not configured");
        _;
    }

    constructor() {
        owner = msg.sender;
        minimumDeposit = 100; // 100 wei minimum deposit
    }

    // Oracle Integration Functions
    function setPriceOracle(address _priceOracle) external onlyOwner {
        require(_priceOracle != address(0), "Invalid oracle address");
        priceOracle = _priceOracle;
        emit OracleUpdated(_priceOracle);
    }

    function setPriceStalenessTreshold(uint256 _threshold) external onlyOwner {
        priceStalenessTreshold = _threshold;
    }

    function setRebalanceThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold <= 10000, "Threshold cannot exceed 100%");
        rebalanceThreshold = _threshold;
    }

    // Enhanced Portfolio Valuation Functions
    function getUserPortfolioValue(
        address user
    ) external view override returns (uint256) {
        if (priceOracle == address(0)) {
            // Fallback to basic calculation if oracle not set
            UserBalance memory balance = _userBalances[user];
            return
                balance.totalInvested +
                balance.pendingInvestment +
                balance.availableBalance;
        }

        return _calculatePortfolioValueCached(user);
    }

    function getUserPortfolioValueLive(
        address user,
        bytes[] calldata priceUpdate
    ) external payable oracleConfigured returns (uint256 totalValue) {
        IPriceOracle oracle = IPriceOracle(priceOracle);

        // Get all supported asset classes
        IPriceOracle.AssetClass[]
            memory assetClasses = new IPriceOracle.AssetClass[](2);
        assetClasses[0] = IPriceOracle.AssetClass.Crypto;
        assetClasses[1] = IPriceOracle.AssetClass.RWA;

        // Get live prices for all assets
        int64[] memory prices = oracle.getMultipleAssetPrices(
            assetClasses,
            priceUpdate
        );

        // Calculate total portfolio value
        for (uint i = 0; i < assetClasses.length; i++) {
            uint256 assetBalance = _userAssetBalances[user][assetClasses[i]];
            if (assetBalance > 0 && prices[i] > 0) {
                totalValue += (assetBalance * uint256(uint64(prices[i]))) / 1e8;
            }
        }

        // Add available balance
        totalValue += _userBalances[user].availableBalance;
    }

    function getAssetAllocation(
        address user
    )
        external
        view
        returns (
            IPriceOracle.AssetClass[] memory assetClasses,
            uint256[] memory amounts
        )
    {
        assetClasses = new IPriceOracle.AssetClass[](4);
        amounts = new uint256[](4);

        assetClasses[0] = IPriceOracle.AssetClass.Crypto;
        assetClasses[1] = IPriceOracle.AssetClass.RWA;
        assetClasses[2] = IPriceOracle.AssetClass.Liquidity;
        assetClasses[3] = IPriceOracle.AssetClass.Stablecoin;

        for (uint i = 0; i < 4; i++) {
            amounts[i] = _userAssetBalances[user][assetClasses[i]];
        }
    }

    // Enhanced Investment Execution with Live Pricing
    function executeInvestmentWithLivePricing(
        uint256 investmentId,
        bytes[] calldata priceUpdate
    )
        external
        payable
        onlyOwner
        investmentExists(investmentId)
        oracleConfigured
    {
        Investment storage investment = _investments[investmentId];
        require(
            investment.status == InvestmentStatus.Pending,
            "Investment not pending"
        );

        IPriceOracle oracle = IPriceOracle(priceOracle);
        IPlanManager planMgr = IPlanManager(planManager);

        // Get investment plan
        IPlanManager.InvestmentPlan memory plan = planMgr.getPlan(
            investment.planId
        );

        // Execute investment based on plan allocations using live prices
        uint256 remainingAmount = investment.totalAmount;

        for (
            uint i = 0;
            i < plan.allocations.length && remainingAmount > 0;
            i++
        ) {
            IPlanManager.AssetAllocation memory allocation = plan.allocations[
                i
            ];

            // Calculate allocation amount
            uint256 allocationAmount = (investment.totalAmount *
                allocation.targetPercentage) / 10000;
            if (allocationAmount > remainingAmount) {
                allocationAmount = remainingAmount;
            }

            // Convert asset class and get live price
            IPriceOracle.AssetClass assetClass = _convertAssetClass(
                allocation.assetClass
            );
            int64 price = oracle.getAssetPrice(assetClass, priceUpdate);
            require(price > 0, "Invalid price for asset");

            // Update user's asset balance
            _userAssetBalances[investment.user][assetClass] += allocationAmount;
            remainingAmount -= allocationAmount;

            emit AssetAllocationUpdated(
                investment.user,
                assetClass,
                allocationAmount
            );
            emit PriceBasedInvestmentExecuted(
                investmentId,
                allocationAmount,
                price
            );
        }

        // Update investment status
        investment.status = InvestmentStatus.Executed;
        investment.executedAmount = investment.totalAmount;
        investment.executedAt = block.timestamp;

        // Update user balance
        address user = investment.user;
        _userBalances[user].pendingInvestment -= investment.totalAmount;
        _userBalances[user].totalInvested += investment.totalAmount;

        emit InvestmentExecuted(investmentId, user, investment.totalAmount);
    }

    // Enhanced Rebalancing with Oracle Integration
    function rebalanceWithLivePricing(
        address user,
        uint256 planId,
        bytes[] calldata priceUpdate
    ) external payable onlyOwner oracleConfigured {
        require(user != address(0), "Invalid user address");

        IPriceOracle oracle = IPriceOracle(priceOracle);
        IPlanManager planMgr = IPlanManager(planManager);

        // Get current portfolio value
        uint256 totalPortfolioValue = this.getUserPortfolioValueLive{
            value: msg.value
        }(user, priceUpdate);
        require(totalPortfolioValue > 0, "No portfolio to rebalance");

        // Get target allocations from plan
        IPlanManager.InvestmentPlan memory plan = planMgr.getPlan(planId);

        // Check if rebalancing is needed
        bool needsRebalancing = _checkRebalancingNeeded(
            user,
            plan,
            totalPortfolioValue
        );
        require(needsRebalancing, "Portfolio within rebalancing threshold");

        // Execute rebalancing
        _executeRebalancing(user, plan, totalPortfolioValue, priceUpdate);

        _lastRebalanceTime[user] = block.timestamp;
        emit PortfolioRebalanced(user, totalPortfolioValue, block.timestamp);
    }

    function checkRebalancingNeeded(
        address user,
        uint256 planId
    ) external view returns (bool needed, uint256 maxDeviation) {
        if (priceOracle == address(0) || planManager == address(0)) {
            return (false, 0);
        }

        uint256 totalValue = _calculatePortfolioValueCached(user);
        if (totalValue == 0) {
            return (false, 0);
        }

        IPlanManager planMgr = IPlanManager(planManager);
        IPlanManager.InvestmentPlan memory plan = planMgr.getPlan(planId);

        return (_checkRebalancingNeeded(user, plan, totalValue), maxDeviation);
    }

    // Deposit Functions (unchanged from original)
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

    // Investment Functions (original)
    function invest(
        uint256 planId,
        uint256 amount
    ) external returns (uint256 investmentId) {
        require(amount > 0, "Investment amount must be greater than 0");
        require(planManager != address(0), "Plan manager not set");
        require(
            _userBalances[msg.sender].availableBalance >= amount,
            "Insufficient balance"
        );

        // Validate that the plan exists and is active
        IPlanManager planManagerContract = IPlanManager(planManager);
        IPlanManager.InvestmentPlan memory plan = planManagerContract.getPlan(planId);
        require(plan.planId == planId, "Plan does not exist");
        require(plan.isActive, "Plan is not active");

        _investmentCounter++;
        investmentId = _investmentCounter;

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

        _userBalances[msg.sender].availableBalance -= amount;
        _userBalances[msg.sender].pendingInvestment += amount;
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

        investment.status = InvestmentStatus.Executed;
        investment.executedAmount = investment.totalAmount;
        investment.executedAt = block.timestamp;

        address user = investment.user;
        _userBalances[user].pendingInvestment -= investment.totalAmount;
        _userBalances[user].totalInvested += investment.totalAmount;

        emit InvestmentExecuted(investmentId, user, investment.totalAmount);
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
                    investment.status = InvestmentStatus.Executed;
                    investment.executedAmount = investment.totalAmount;
                    investment.executedAt = block.timestamp;

                    address user = investment.user;
                    _userBalances[user].pendingInvestment -= investment
                        .totalAmount;
                    _userBalances[user].totalInvested += investment.totalAmount;

                    emit InvestmentExecuted(
                        investmentId,
                        user,
                        investment.totalAmount
                    );
                }
            }
        }
    }

    // Legacy rebalancing function
    function rebalance(address user, uint256 planId) external onlyOwner {
        require(user != address(0), "Invalid user address");
        uint256 portfolioValue = this.getUserPortfolioValue(user);
        require(portfolioValue > 0, "No portfolio to rebalance");
    }

    // View Functions (unchanged from original)
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

        uint256 pendingCount = 0;
        for (uint256 i = 0; i < investmentIds.length; i++) {
            if (
                _investments[investmentIds[i]].status ==
                InvestmentStatus.Pending
            ) {
                pendingCount++;
            }
        }

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
        return 0; // Placeholder implementation
    }

    // Internal Functions
    function _processDeposit(
        address user,
        uint256 amount,
        DepositType depositType
    ) internal {
        _depositCounter++;
        uint256 depositId = _depositCounter;

        _deposits[depositId] = UserDeposit({
            user: user,
            amount: amount,
            depositType: depositType,
            timestamp: block.timestamp,
            processed: true
        });

        _userBalances[user].totalDeposited += amount;
        _userBalances[user].availableBalance += amount;
        _userDeposits[user].push(depositId);

        emit DepositReceived(user, amount, depositType);
    }

    function _calculatePortfolioValueCached(
        address user
    ) internal view returns (uint256 totalValue) {
        // This would use cached prices from the oracle
        // For simplicity, returning basic calculation
        UserBalance memory balance = _userBalances[user];
        return
            balance.totalInvested +
            balance.pendingInvestment +
            balance.availableBalance;
    }

    function _convertAssetClass(
        IPlanManager.AssetClass planAssetClass
    ) internal pure returns (IPriceOracle.AssetClass) {
        if (planAssetClass == IPlanManager.AssetClass.Crypto) {
            return IPriceOracle.AssetClass.Crypto;
        } else if (planAssetClass == IPlanManager.AssetClass.RWA) {
            return IPriceOracle.AssetClass.RWA;
        } else if (planAssetClass == IPlanManager.AssetClass.Liquidity) {
            return IPriceOracle.AssetClass.Liquidity;
        } else if (planAssetClass == IPlanManager.AssetClass.Stablecoin) {
            return IPriceOracle.AssetClass.Stablecoin;
        }
        revert("Unsupported asset class");
    }

    function _checkRebalancingNeeded(
        address user,
        IPlanManager.InvestmentPlan memory plan,
        uint256 totalValue
    ) internal view returns (bool) {
        for (uint i = 0; i < plan.allocations.length; i++) {
            IPlanManager.AssetAllocation memory allocation = plan.allocations[
                i
            ];
            IPriceOracle.AssetClass assetClass = _convertAssetClass(
                allocation.assetClass
            );

            uint256 currentAmount = _userAssetBalances[user][assetClass];
            uint256 currentPercentage = totalValue > 0
                ? (currentAmount * 10000) / totalValue
                : 0;

            uint256 deviation = currentPercentage > allocation.targetPercentage
                ? currentPercentage - allocation.targetPercentage
                : allocation.targetPercentage - currentPercentage;

            if (deviation > rebalanceThreshold) {
                return true;
            }
        }
        return false;
    }

    function _executeRebalancing(
        address user,
        IPlanManager.InvestmentPlan memory plan,
        uint256 totalValue,
        bytes[] calldata priceUpdate
    ) internal {
        // This is a simplified rebalancing implementation
        // In a full implementation, this would involve:
        // 1. Calculate current vs target allocations
        // 2. Execute trades on DEXs to rebalance
        // 3. Update user asset balances accordingly

        // For now, just update allocations based on target percentages
        for (uint i = 0; i < plan.allocations.length; i++) {
            IPlanManager.AssetAllocation memory allocation = plan.allocations[
                i
            ];
            IPriceOracle.AssetClass assetClass = _convertAssetClass(
                allocation.assetClass
            );

            uint256 targetAmount = (totalValue * allocation.targetPercentage) /
                10000;
            _userAssetBalances[user][assetClass] = targetAmount;

            emit AssetAllocationUpdated(user, assetClass, targetAmount);
        }
    }

    // Administrative Functions
    function setPlanManager(address _planManager) external onlyOwner {
        require(_planManager != address(0), "Invalid plan manager address");
        planManager = _planManager;
    }

    function setMinimumDeposit(uint256 amount) external onlyOwner {
        minimumDeposit = amount;
    }
}
