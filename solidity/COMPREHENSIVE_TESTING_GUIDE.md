# 404 Poverty Not Found - Comprehensive Testing Guide

## Overview
This guide provides step-by-step instructions for testing all implemented functionality of the 404 Poverty Not Found DeFi investment platform.

## Quick Start Commands

### 1. Environment Setup
```bash
# Navigate to project directory
cd solidity/

# Start local blockchain
anvil --port 8545 --accounts 10 --balance 1000 --host 0.0.0.0 --chain-id 31337

# In another terminal, set environment variables
export RPC_URL="http://127.0.0.1:8545"
export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PRIVATE_KEY_USER1="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export PRIVATE_KEY_USER2="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
```

---

## Feature Testing Matrix

| Feature | Test Script | Status | Description |
|---------|-------------|--------|-------------|
| **Plan Creation** | `PlanCreationVerification.s.sol` | ✅ Working | Create and verify investment plans |
| **ERC20 Integration** | `TestERC20Integration.s.sol` | ✅ Working | Full token integration testing |
| **Investment Flow** | `CryptoOnlyInvestmentTest.s.sol` | ✅ Working | Complete investment workflow |
| **Token Deployment** | `DeployTestnetTokens.s.sol` | ✅ Working | Deploy mock ERC20 tokens |
| **Full Deployment** | `DeployTestnetIntegration.s.sol` | ✅ Working | Complete system deployment |

---

## Test Suite 1: Basic Plan Management

### **Feature**: Investment Plan Creation and Verification

**Test Script**: `PlanCreationVerification.s.sol`

**What it tests**:
- ✅ PlanManager contract deployment
- ✅ Creation of multiple investment plan types
- ✅ Plan storage and retrieval
- ✅ Risk score calculation
- ✅ Asset allocation validation

**Test Data**:
```solidity
// Aggressive Plan (Risk Score: 7)
50% WBTC, 30% WETH, 20% LINK

// Conservative Plan (Risk Score: 5)
40% WETH, 30% WBTC, 30% USDC

// Balanced Plan (Risk Score: 7)
60% WETH, 40% WBTC
```

**Commands**:
```bash
# Run plan creation test
forge script script/PlanCreationVerification.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Verify results
cast call <PLAN_MANAGER_ADDRESS> "getTotalPlans()" --rpc-url $RPC_URL
cast call <PLAN_MANAGER_ADDRESS> "getPlan(uint256)" 1 --rpc-url $RPC_URL
cast call <PLAN_MANAGER_ADDRESS> "getPlan(uint256)" 2 --rpc-url $RPC_URL
cast call <PLAN_MANAGER_ADDRESS> "getPlan(uint256)" 3 --rpc-url $RPC_URL
```

**Expected Results**:
- ✅ 3 plans created successfully
- ✅ Plan IDs: 1, 2, 3
- ✅ Risk scores: 7, 5, 7 respectively
- ✅ All plans marked as active

---

## Test Suite 2: ERC20 Token Integration

### **Feature**: Full ERC20 Token Integration with Investment Engine

**Test Script**: `TestERC20Integration.s.sol`

**What it tests**:
- ✅ Mock ERC20 token deployment with faucet
- ✅ InvestmentEngineV2 with real token support
- ✅ Token deposits requiring ERC20 approvals
- ✅ Investment execution with actual token allocation
- ✅ Multi-token portfolio tracking
- ✅ Token balance verification

**Test Data**:
```solidity
// Mock Tokens Deployed
USDC: 6 decimals, 1M supply, 1000 faucet
WBTC: 8 decimals, 100 supply, 0.01 faucet
WETH: 18 decimals, 1000 supply, 1 faucet
LINK: 18 decimals, 10k supply, 100 faucet

// Test Investment Plan
40% WETH, 30% WBTC, 20% LINK, 10% USDC

// Test User Deposits
User1: 2000 USDC deposit
Investment: 1000 USDC worth across tokens
```

**Commands**:
```bash
# Run full ERC20 integration test
forge script script/TestERC20Integration.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Claim tokens from faucet
cast send <USDC_ADDRESS> "faucet()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY_USER1
cast send <WBTC_ADDRESS> "faucet()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY_USER1

# Check token balances
cast call <USDC_ADDRESS> "balanceOf(address)" <USER_ADDRESS> --rpc-url $RPC_URL
cast call <INVESTMENT_ENGINE_ADDRESS> "getUserTokenBalance(address,address)" <USER_ADDRESS> <TOKEN_ADDRESS> --rpc-url $RPC_URL
```

**Expected Results**:
- ✅ All tokens deployed successfully
- ✅ User can deposit USDC tokens (requires approval)
- ✅ Investment execution allocates tokens according to plan percentages
- ✅ User holds multiple tokens after investment
- ✅ Portfolio value calculated correctly

---

## Test Suite 3: Complete Investment Workflow

### **Feature**: End-to-End Investment Process

**Test Script**: `CryptoOnlyInvestmentTest.s.sol`

**What it tests**:
- ✅ System deployment and configuration
- ✅ Multiple investment plan creation
- ✅ User deposit processing
- ✅ Investment creation and execution
- ✅ Balance tracking through all states
- ✅ Portfolio analytics

**Test Data**:
```solidity
// Investment Plans Created
1. Aggressive: 50% WBTC, 30% WETH, 20% LINK
2. Conservative: 40% WETH, 30% WBTC, 30% USDC
3. Custom: 25% each of WBTC, WETH, LINK, UNI

// User Deposits
User1: 10,000 units (Salary)
User2: 5,000 units (Manual)

// Investments
Owner: 8,000 units → Aggressive Plan
Owner: 2,000 units → Conservative Plan
Owner: 4,000 units → Custom Plan
```

**Commands**:
```bash
# Run complete workflow test
forge script script/CryptoOnlyInvestmentTest.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Check final balances
cast call <INVESTMENT_ENGINE_ADDRESS> "getUserBalance(address)" <USER_ADDRESS> --rpc-url $RPC_URL
cast call <INVESTMENT_ENGINE_ADDRESS> "getUserPortfolioValue(address)" <USER_ADDRESS> --rpc-url $RPC_URL

# View all investments
cast call <INVESTMENT_ENGINE_ADDRESS> "getUserInvestments(address)" <USER_ADDRESS> --rpc-url $RPC_URL
```

**Expected Results**:
- ✅ All 3 investment plans created
- ✅ User deposits processed correctly
- ✅ Investments created and executed successfully
- ✅ Final balances: Available + Invested = Total Deposited
- ✅ Portfolio analytics display correctly

---

## Test Suite 4: Token Deployment and Management

### **Feature**: Testnet Token Infrastructure

**Test Script**: `DeployTestnetTokens.s.sol`

**What it tests**:
- ✅ Mock ERC20 deployment with realistic parameters
- ✅ Faucet functionality for each token
- ✅ Token metadata (name, symbol, decimals)
- ✅ Initial supply and faucet amounts

**Test Data**:
```solidity
// Token Specifications
USDC: "Mock USD Coin", 6 decimals, 1M supply
WBTC: "Mock Wrapped Bitcoin", 8 decimals, 100 supply
WETH: "Mock Wrapped Ether", 18 decimals, 1000 supply
LINK: "Mock Chainlink Token", 18 decimals, 100k supply
UNI: "Mock Uniswap Token", 18 decimals, 100k supply

// Faucet Amounts (per hour)
USDC: 1000 tokens
WBTC: 0.01 tokens
WETH: 1 token
LINK: 100 tokens
UNI: 50 tokens
```

**Commands**:
```bash
# Deploy all test tokens
forge script script/DeployTestnetTokens.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Test faucet functionality
cast send <TOKEN_ADDRESS> "faucet()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY_USER1

# Check faucet cooldown
cast call <TOKEN_ADDRESS> "canClaimFaucet(address)" <USER_ADDRESS> --rpc-url $RPC_URL
cast call <TOKEN_ADDRESS> "timeUntilNextClaim(address)" <USER_ADDRESS> --rpc-url $RPC_URL

# Verify token properties
cast call <TOKEN_ADDRESS> "name()" --rpc-url $RPC_URL
cast call <TOKEN_ADDRESS> "symbol()" --rpc-url $RPC_URL
cast call <TOKEN_ADDRESS> "decimals()" --rpc-url $RPC_URL
cast call <TOKEN_ADDRESS> "totalSupply()" --rpc-url $RPC_URL
```

**Expected Results**:
- ✅ All 5 tokens deployed successfully
- ✅ Faucet provides tokens with 1-hour cooldown
- ✅ Token metadata matches specifications
- ✅ Balances update correctly after faucet claims

---

## Test Suite 5: Complete System Deployment

### **Feature**: Full Platform Deployment with Sample Data

**Test Script**: `DeployTestnetIntegration.s.sol`

**What it tests**:
- ✅ Complete system deployment (all contracts + tokens)
- ✅ Contract integration and configuration
- ✅ Sample investment plan creation
- ✅ Token reserve setup for testing
- ✅ Deployment verification commands

**Test Data**:
```solidity
// System Components
- PlanManager contract
- InvestmentEngine contract
- 5 Mock ERC20 tokens with faucets
- 3 Sample investment plans

// Sample Plans
1. Aggressive: 50% WBTC, 30% WETH, 20% LINK
2. Conservative: 40% WETH, 30% WBTC, 30% USDC
3. Balanced: 25% each of WBTC, WETH, LINK, UNI

// Token Reserves (for contract)
10,000 units of each token for simulated purchases
```

**Commands**:
```bash
# Deploy complete system
forge script script/DeployTestnetIntegration.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Verify deployment
cast call <PLAN_MANAGER_ADDRESS> "getTotalPlans()" --rpc-url $RPC_URL
cast call <INVESTMENT_ENGINE_ADDRESS> "planManager()" --rpc-url $RPC_URL

# Test token faucets
cast send <USDC_ADDRESS> "faucet()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY_USER1
cast send <WBTC_ADDRESS> "faucet()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY_USER1

# Check contract token reserves
cast call <USDC_ADDRESS> "balanceOf(address)" <INVESTMENT_ENGINE_ADDRESS> --rpc-url $RPC_URL
```

**Expected Results**:
- ✅ All contracts deployed and connected
- ✅ 3 sample plans created successfully
- ✅ Token reserves funded for testing
- ✅ Faucets operational for all tokens
- ✅ System ready for end-to-end testing

---

## Manual Testing Scenarios

### **Scenario 1: New User Onboarding**
```bash
# 1. User claims tokens from faucets
cast send $USDC_ADDRESS "faucet()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY_USER1

# 2. User approves tokens for deposit
cast send $USDC_ADDRESS "approve(address,uint256)" $INVESTMENT_ENGINE_ADDRESS 2000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY_USER1

# 3. User deposits tokens
cast send $INVESTMENT_ENGINE_ADDRESS "depositToken(address,uint256,uint8)" $USDC_ADDRESS 1000000000 1 --rpc-url $RPC_URL --private-key $PRIVATE_KEY_USER1

# 4. Check user balance
cast call $INVESTMENT_ENGINE_ADDRESS "getUserBalance(address)" $USER1_ADDRESS --rpc-url $RPC_URL
```

### **Scenario 2: Investment Creation and Execution**
```bash
# 1. User creates investment
cast send $INVESTMENT_ENGINE_ADDRESS "invest(uint256,uint256)" 1 500000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY_USER1

# 2. Admin executes investment
cast send $INVESTMENT_ENGINE_ADDRESS "executeInvestment(uint256)" 1 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# 3. Check user token holdings
cast call $INVESTMENT_ENGINE_ADDRESS "getUserTokens(address)" $USER1_ADDRESS --rpc-url $RPC_URL

# 4. Check individual token balances
cast call $INVESTMENT_ENGINE_ADDRESS "getUserTokenBalance(address,address)" $USER1_ADDRESS $WBTC_ADDRESS --rpc-url $RPC_URL
```

### **Scenario 3: Portfolio Rebalancing**
```bash
# 1. Check current portfolio value
cast call $INVESTMENT_ENGINE_ADDRESS "getUserPortfolioValue(address)" $USER1_ADDRESS --rpc-url $RPC_URL

# 2. Trigger rebalancing (admin function)
cast send $INVESTMENT_ENGINE_ADDRESS "rebalance(address,uint256)" $USER1_ADDRESS 1 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# 3. Verify changes in token distribution
cast call $INVESTMENT_ENGINE_ADDRESS "getUserTokens(address)" $USER1_ADDRESS --rpc-url $RPC_URL
```

---

## Troubleshooting Common Issues

### **Issue 1: "Insufficient balance" on investment**
```bash
# Check user's available balance
cast call $INVESTMENT_ENGINE_ADDRESS "getUserBalance(address)" $USER_ADDRESS --rpc-url $RPC_URL

# Verify user has made deposits
cast call $INVESTMENT_ENGINE_ADDRESS "getUserDeposits(address)" $USER_ADDRESS --rpc-url $RPC_URL
```

### **Issue 2: "ERC20: transfer amount exceeds allowance"**
```bash
# Check current allowance
cast call $TOKEN_ADDRESS "allowance(address,address)" $USER_ADDRESS $INVESTMENT_ENGINE_ADDRESS --rpc-url $RPC_URL

# Increase allowance
cast send $TOKEN_ADDRESS "approve(address,uint256)" $INVESTMENT_ENGINE_ADDRESS 1000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY_USER1
```

### **Issue 3: "Faucet cooldown not met"**
```bash
# Check if user can claim
cast call $TOKEN_ADDRESS "canClaimFaucet(address)" $USER_ADDRESS --rpc-url $RPC_URL

# Check time until next claim
cast call $TOKEN_ADDRESS "timeUntilNextClaim(address)" $USER_ADDRESS --rpc-url $RPC_URL
```

---

## Performance Benchmarks

### **Gas Usage Estimates**

| Operation | Gas Used | USD Cost (20 gwei) |
|-----------|----------|-------------------|
| Deploy PlanManager | ~1,400,000 | ~$7.00 |
| Deploy InvestmentEngine | ~1,500,000 | ~$7.50 |
| Deploy Mock Token | ~1,200,000 | ~$6.00 |
| Create Investment Plan | ~480,000 | ~$2.40 |
| Token Deposit | ~180,000 | ~$0.90 |
| Create Investment | ~130,000 | ~$0.65 |
| Execute Investment | ~200,000 | ~$1.00 |
| Token Faucet Claim | ~80,000 | ~$0.40 |

### **Transaction Throughput**
- **Plan Creation**: ~2 seconds per plan
- **Token Deployment**: ~15 seconds for all 5 tokens
- **Investment Execution**: ~3 seconds per investment
- **Complete System Deployment**: ~2 minutes

---

## Testnet Deployment Checklist

### **Pre-Deployment**
- [ ] Testnet ETH in deployer wallet
- [ ] RPC URL configured
- [ ] Private keys secured
- [ ] Foundry environment setup

### **Deployment Steps**
- [ ] Deploy token contracts
- [ ] Deploy core contracts (PlanManager, InvestmentEngine)
- [ ] Connect contracts
- [ ] Create sample investment plans
- [ ] Fund contract with token reserves
- [ ] Verify all deployments

### **Post-Deployment Testing**
- [ ] Test token faucets
- [ ] Test user deposits
- [ ] Test investment creation
- [ ] Test investment execution
- [ ] Verify portfolio tracking
- [ ] Test edge cases

### **Documentation Updates**
- [ ] Update contract addresses in config
- [ ] Update API endpoints
- [ ] Update frontend integration
- [ ] Create user guides

---

## Success Criteria

### **✅ All Tests Must Pass**
1. **Plan Creation**: 3 plans created with correct allocations
2. **Token Integration**: Real ERC20 deposits and transfers working
3. **Investment Flow**: Complete workflow from deposit to execution
4. **Portfolio Tracking**: Accurate multi-token balance tracking
5. **Faucet System**: Users can claim test tokens reliably

### **✅ System Ready Indicators**
- All contracts deployed without errors
- All test scripts execute successfully
- Gas usage within expected ranges
- No reverted transactions in test flows
- User balances accurate throughout process

---

## Next Steps for Production

1. **Price Oracle Integration**: Replace 1:1 token conversion with real price feeds
2. **DEX Integration**: Add Uniswap integration for actual token swaps
3. **Slippage Protection**: Implement slippage controls for token purchases
4. **Advanced Rebalancing**: Complete rebalancing algorithm implementation
5. **Security Audit**: Comprehensive security review before mainnet

---

*Last Updated*: January 2025
*Testing Framework*: Foundry with Anvil local blockchain
*Coverage*: All implemented features tested and verified