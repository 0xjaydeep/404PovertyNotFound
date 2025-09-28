# Crypto-Only Investment Testing Guide

## Overview
This guide walks through testing crypto-only investment functionality using the 404 Poverty Not Found platform's smart contracts, following the established testing patterns from TESTING.md and INVESTMENT_TESTING.md.

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

3. **Start local Anvil node** (in separate terminal):
   ```bash
   anvil
   ```

## Testing Scripts

### 1. CryptoOnlyInvestmentTest.s.sol ✅ WORKING
**Purpose**: Comprehensive testing of crypto-only investment plans with multiple portfolio types.

**Features Tested**:
- Contract deployment and configuration
- Crypto-only investment plan creation (Aggressive, Conservative, Custom)
- User deposit functionality (Salary, Manual types)
- Portfolio analytics and balance tracking
- Risk score calculations for crypto portfolios
- Investment plan validation

**Usage**:
```bash
# Test crypto-only investment functionality
forge script script/CryptoOnlyInvestmentTest.s.sol:CryptoOnlyInvestmentTest --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

**Output**: Shows complete crypto investment workflow with portfolio analytics.

## Crypto Portfolio Types Tested

### 1. Aggressive Crypto Portfolio
- **Risk Score**: 7 (High Risk)
- **Allocation**: 50% WBTC, 30% WETH, 20% LINK
- **Use Case**: High-risk, high-reward crypto exposure

### 2. Conservative Crypto Portfolio
- **Risk Score**: 5 (Medium Risk)
- **Allocation**: 40% WETH, 30% WBTC, 30% USDC
- **Use Case**: Balanced crypto exposure with stablecoin hedge

### 3. Custom Diversified Portfolio
- **Risk Score**: 7 (High Risk)
- **Allocation**: 25% each of WBTC, WETH, LINK, UNI
- **Use Case**: Diversified crypto exposure across major tokens

## Manual Testing Commands

### Deploy Individual Contracts
```bash
# Deploy PlanManager only
forge script script/DeployPlanManager.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# Deploy InvestmentEngine with PlanManager integration
forge script script/DeployInvestmentEngine.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### Verify Plan Creation ✅ WORKING

**New Dedicated Test Script**: `PlanCreationVerification.s.sol`

```bash
# Run dedicated plan creation test (creates 3 crypto plans)
forge script script/PlanCreationVerification.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

**Manual Verification Commands** (use the deployed contract address):

```bash
# Check total plans created (should return 3 in hex: 0x03)
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getTotalPlans()" --rpc-url http://127.0.0.1:8545

# Get plan details for plan ID 1 (Aggressive Crypto Portfolio)
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getPlan(uint256)" 1 --rpc-url http://127.0.0.1:8545

# Get plan details for plan ID 2 (Conservative Mixed Portfolio)
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getPlan(uint256)" 2 --rpc-url http://127.0.0.1:8545

# Get plan details for plan ID 3 (Balanced Crypto Portfolio)
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getPlan(uint256)" 3 --rpc-url http://127.0.0.1:8545

# View all active plans (returns complex struct data)
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getActivePlans()" --rpc-url http://127.0.0.1:8545
```

**Converting Hex Results**:
```bash
# Convert hex to decimal for easier reading
cast --to-dec 0x0000000000000000000000000000000000000000000000000000000000000003
# Returns: 3 (total plans)
```

### User Deposit Testing
```bash
# Admin deposits for test user (Salary deposit type)
cast send $INVESTMENT_ENGINE_ADDRESS "depositForUser(address,uint256,uint8)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  10000 \
  1 \
  --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Manual deposit for another user
cast send $INVESTMENT_ENGINE_ADDRESS "depositForUser(address,uint256,uint8)" \
  0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC \
  5000 \
  0 \
  --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Check User Balance
```bash
# Check user's available balance
cast call $INVESTMENT_ENGINE_ADDRESS "getUserBalance(address)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --rpc-url http://127.0.0.1:8545

# Check user's portfolio value
cast call $INVESTMENT_ENGINE_ADDRESS "getUserPortfolioValue(address)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --rpc-url http://127.0.0.1:8545
```

## Test Results Analysis

### ✅ Successfully Tested Functions

| Function | Test Status | Notes |
|----------|-------------|-------|
| `createPlan()` | ✅ PASS | Creates crypto-only plans with correct risk scores |
| `depositForUser()` | ✅ PASS | Handles salary and manual deposits |
| `getUserBalance()` | ✅ PASS | Accurate balance tracking |
| `validateAllocation()` | ✅ PASS | Ensures 100% allocation requirement |
| `calculateRiskScore()` | ✅ PASS | Proper crypto risk scoring (7 for pure crypto) |

### Balance State Transitions Verified

```
Initial: { totalDeposited: 0, availableBalance: 0, pendingInvestment: 0, totalInvested: 0 }
↓ Deposit 10000 (User1) + 5000 (User2)
After Deposits: {
  User1: { totalDeposited: 10000, availableBalance: 10000, pendingInvestment: 0, totalInvested: 0 }
  User2: { totalDeposited: 5000, availableBalance: 5000, pendingInvestment: 0, totalInvested: 0 }
}
```

### Crypto Portfolio Risk Scores
- **Pure Crypto Portfolio** (WBTC + WETH + LINK): Risk Score = 7
- **Mixed Crypto Portfolio** (Crypto + Stablecoin): Risk Score = 5
- **Diversified Crypto Portfolio** (4 crypto assets): Risk Score = 7

## Mock Token Addresses Used

Following the established testing pattern:

```solidity
// Crypto Assets (AssetClass.Crypto = 0, Risk Factor = 7)
WBTC_ADDRESS = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599    // Mock WBTC
WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2    // Mock WETH
LINK_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA    // Mock LINK
UNI_ADDRESS = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984     // Mock UNI

// Stablecoin (AssetClass.Stablecoin = 3, Risk Factor = 1)
USDC_ADDRESS = 0xA0B86a33e6417e0f0e5B4fBC4fB74b95b2AB1c7f    // Mock USDC

// Test User Addresses (Anvil default accounts)
USER1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8         // Anvil account 1
USER2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC         // Anvil account 2
```

## Asset Classes and Risk Factors

Following the established PlanManager configuration:

| Asset Class | ID | Risk Factor (1-10) | Description |
|-------------|----|--------------------|-------------|
| Crypto | 0 | 7 | High risk, volatile crypto assets |
| RWA | 1 | 4 | Real World Assets (stocks, bonds) |
| Liquidity | 2 | 6 | LP tokens, moderate risk |
| Stablecoin | 3 | 1 | Lowest risk, stable value |

## Percentage Format
- Use basis points (10000 = 100%)
- Example: 2500 = 25%, 5000 = 50%
- Total allocation must equal 10000 (100%)

## Troubleshooting

Following the established testing patterns:

1. **Connection refused**: Make sure Anvil is running on port 8545
2. **Compilation errors**: Ensure `via_ir = true` is set in foundry.toml
3. **Invalid checksum**: All addresses in scripts are properly checksummed
4. **Gas estimation**: Scripts include gas estimation for deployment costs
5. **"Insufficient balance" errors**: Ensure deposits are made before investments
6. **"Invalid allocation"**: Ensure total percentage equals 10000 (100%)

## Building and Compilation

```bash
# Build all contracts
forge build

# Run basic tests (if any)
forge test

# Check compilation without broadcast
forge script script/CryptoOnlyInvestmentTest.s.sol
```

## Integration with Existing Testing Framework

The crypto-only investment test follows the same patterns as:
- **TESTING.md**: PlanManager testing approach
- **INVESTMENT_TESTING.md**: InvestmentEngine testing approach
- Uses same mock addresses and user accounts
- Follows same deployment and verification patterns

## Contract Limitations ⚠️

Following the analysis from INVESTMENT_TESTING.md:

1. **Investment Function Design**:
   - `invest()` uses `msg.sender` as the investor
   - No `investForUser()` function for admin-initiated investments
   - Limits multi-user testing scenarios in scripts

2. **Current Test Scope**:
   - Tests plan creation and deposits successfully ✅
   - Investment execution requires user signatures (noted in script)
   - Portfolio analytics and balance tracking working ✅

## Next Steps

1. **Complete Current Testing**: All basic crypto-only functionality verified ✅
2. **Integration Testing**: Test with other contract modules
3. **Performance Testing**: Gas optimization for crypto portfolios
4. **Uniswap V4 Integration**: Automated crypto investment execution
5. **Real Network Testing**: Deploy to testnets with actual token contracts

---

*Last Updated*: September 27, 2025
*Framework*: Foundry with Anvil local testing
*Integration*: Follows established testing patterns from TESTING.md and INVESTMENT_TESTING.md