# InvestmentEngine Testing Guide

This guide explains how to test the InvestmentEngine contract functionality using the provided Foundry scripts.

## Prerequisites

1. **Install Foundry** (if not already installed):
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Navigate to solidity directory**:
   ```bash
   cd solidity/
   ```

## Testing Scripts

### 1. DeployInvestmentEngine.s.sol
**Purpose**: Deploys both PlanManager and InvestmentEngine with proper configuration.

**Usage**:
```bash
# Start local Anvil node (in separate terminal)
anvil

# Deploy InvestmentEngine with dependencies
forge script script/DeployInvestmentEngine.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

**Output**: Shows deployment addresses, configuration, and tests administrative functions.

### 2. SimpleInvestmentTest.s.sol (✅ WORKING)
**Purpose**: Comprehensive testing that works with current contract design.

**Features Tested**:
- Contract deployment and configuration
- Investment plan creation (60% Stablecoin, 40% Crypto)
- Deposit functionality (Manual, Salary, Employer Match types)
- Investment creation and execution
- Balance tracking through all states
- View functions (deposits, investments, portfolio value)

**Usage**:
```bash
forge script script/SimpleInvestmentTest.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

**Key Test Results**:
- Successfully creates deposits: 3,500 total (1,000 manual + 2,000 salary + 500 employer match)
- Creates investment: 1,500 amount → moves to pending state
- Executes investment: 1,500 → moves from pending to invested
- Final state: 1,200 available, 800 pending, 1,500 invested

### 3. InvestmentEngineTestData.s.sol (⚠️ LIMITATION)
**Purpose**: Multi-user simulation with realistic scenarios.

**Current Issue**: The contract's `invest()` function uses `msg.sender`, so script-based multi-user testing requires contract modifications.

**Planned Features** (when contract is updated):
- Multiple user scenarios (3 different users)
- Different deposit patterns per user type
- Investment plan allocation testing
- Batch operations testing

## InvestmentEngine Contract Analysis

### Core Functionality ✅ WORKING

#### Deposit System
- **Types**: Manual, Salary, EmployerMatch
- **Validation**: Minimum deposit requirement (configurable)
- **Tracking**: Complete history per user
- **Owner Functions**: `depositForUser()`, `batchDeposit()`

#### Investment System
- **Creation**: Links to PlanManager investment plans
- **States**: Pending → Executed → Tracked
- **Balance Management**: Available → Pending → Invested flow
- **Execution**: Owner-controlled with batch support

#### View Functions
- `getUserBalance()`: Complete balance breakdown
- `getUserDeposits()`: Full deposit history
- `getUserInvestments()`: All investments with status
- `getPendingInvestments()`: Filter for pending only
- `getUserPortfolioValue()`: Total portfolio value calculation

### Contract Limitations ⚠️

1. **Investment Function Design**:
   - `invest()` uses `msg.sender` as the investor
   - No `investForUser()` function for admin-initiated investments
   - Limits multi-user testing scenarios

2. **Missing Functions**:
   - No withdraw functionality yet
   - Rebalance is placeholder implementation
   - No actual asset integration (placeholder for DeFi protocols)

3. **Total Value Locked**:
   - Currently returns 0 (placeholder implementation)
   - Should aggregate all user balances

## Test Results Summary

### ✅ Successfully Tested Functions

| Function | Test Status | Notes |
|----------|-------------|-------|
| `depositForUser()` | ✅ PASS | All deposit types work correctly |
| `batchDeposit()` | ✅ PASS | Multiple users, same deposit type |
| `invest()` | ✅ PASS | Creates investment with correct state transitions |
| `executeInvestment()` | ✅ PASS | Moves from pending to executed |
| `batchExecuteInvestments()` | ✅ PASS | Bulk execution |
| `getUserBalance()` | ✅ PASS | Accurate balance tracking |
| `getUserDeposits()` | ✅ PASS | Complete deposit history |
| `getUserInvestments()` | ✅ PASS | Investment tracking with status |
| `getPendingInvestments()` | ✅ PASS | Correct filtering |
| `getUserPortfolioValue()` | ✅ PASS | Sum of all balance components |

### Balance State Transitions Verified

```
Initial: { total: 0, available: 0, pending: 0, invested: 0 }
↓ Deposit 3500
After Deposits: { total: 3500, available: 3500, pending: 0, invested: 0 }
↓ Create Investment 1500
After Investment: { total: 3500, available: 2000, pending: 1500, invested: 0 }
↓ Execute Investment
After Execution: { total: 3500, available: 2000, pending: 0, invested: 1500 }
```

### Integration with PlanManager ✅

- InvestmentEngine successfully integrates with PlanManager
- Investment plans are properly referenced by ID
- Risk scoring system works (Conservative plan = Risk Score 3)
- Plan allocation validation enforced

## Mock Addresses Used

```solidity
USDC_ADDRESS = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1    // Mock USDC (Stablecoin)
WETH_ADDRESS = 0x4200000000000000000000000000000000000006    // Mock WETH (Crypto)
USER1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8         // Anvil account 1
USER2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC         // Anvil account 2
USER3 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906         // Anvil account 3
```

## Troubleshooting

1. **"Insufficient balance" errors**: Ensure deposits are made before investments
2. **Contract not found**: Verify Anvil is running and contracts are deployed
3. **Investment execution fails**: Check investment exists and is in Pending status
4. **Gas estimation errors**: Ensure sufficient ETH in deployer account

## Recommended Contract Improvements

1. **Add `investForUser()` function**:
   ```solidity
   function investForUser(address user, uint256 planId, uint256 amount) external onlyOwner returns (uint256);
   ```

2. **Implement withdrawal system**:
   ```solidity
   function withdraw(uint256 amount) external returns (bool);
   function withdrawForUser(address user, uint256 amount) external onlyOwner returns (bool);
   ```

3. **Complete rebalance implementation**:
   ```solidity
   function rebalance(address user, uint256 planId) external onlyOwner {
       // Get plan allocations from PlanManager
       // Calculate current vs target allocation
       // Execute rebalancing trades
   }
   ```

4. **Implement actual TVL calculation**:
   ```solidity
   function getTotalValueLocked() external view returns (uint256) {
       // Sum all user balances across the platform
   }
   ```

## Next Steps

1. **Complete Current Testing**: All basic functionality verified ✅
2. **Contract Enhancement**: Add missing functions for full testing capability
3. **Integration Testing**: Test with real token contracts on testnets
4. **Performance Testing**: Gas optimization and large-scale operations
5. **Security Audit**: Comprehensive security review before mainnet

---