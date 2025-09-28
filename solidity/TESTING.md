# PlanManager Testing Guide

This guide explains how to test the PlanManager contract functionality using the provided Foundry scripts.

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

### 1. DeployPlanManager.s.sol
**Purpose**: Simple deployment script that deploys PlanManager and shows initial state.

**Usage**:
```bash
# Start local Anvil node (in separate terminal)
anvil

# Deploy PlanManager
forge script script/DeployPlanManager.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

**Output**: Shows deployment address, owner, and initial asset risk factors.

### 2. InteractivePlanTest.s.sol
**Purpose**: Comprehensive testing of individual PlanManager functions with edge cases.

**Features Tested**:
- Plan creation (simple 2-asset plan)
- Allocation validation (100% single asset)
- Plan updates (changing allocations and observing risk score changes)
- View functions (getAllPlans, getActivePlans, etc.)
- Risk score calculations for different portfolios

**Usage**:
```bash
forge script script/InteractivePlanTest.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### 3. PlanManagerTestData.s.sol
**Purpose**: Creates realistic investment plan scenarios with sample data.

**Plans Created**:
- **Conservative Plan**: 60% Stablecoin, 30% RWA Bonds, 10% Crypto (Risk Score: ~2)
- **Balanced Plan**: 30% Stablecoin, 35% RWA Stocks, 20% Crypto, 15% Liquidity (Risk Score: ~4)
- **Aggressive Plan**: 10% Stablecoin, 20% RWA, 70% Crypto (Risk Score: ~5)
- **Custom Plan**: 70% RWA (Stocks + Bonds), 30% Liquidity (Risk Score: ~4)

**Usage**:
```bash
forge script script/PlanManagerTestData.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

## Asset Classes and Risk Factors

The PlanManager uses the following risk scoring system:

| Asset Class | Risk Factor (1-10) | Description |
|-------------|-------------------|-------------|
| Stablecoin  | 1                 | Lowest risk, stable value |
| RWA         | 4                 | Real World Assets (stocks, bonds) |
| Liquidity   | 6                 | LP tokens, moderate risk |
| Crypto      | 7                 | Highest risk, volatile |

## Mock Token Addresses

The test scripts use these mock addresses:

```solidity
USDC_ADDRESS = 0xa0B86a33e6417aEB573D4aebcA271d5f50E0c1b1    // Mock USDC
WETH_ADDRESS = 0x4200000000000000000000000000000000000006    // Mock WETH
WBTC_ADDRESS = 0x68f180fcCe6836688e9084f035309E29Bf0A2095    // Mock WBTC
RWA_STOCK_ADDRESS = 0x1234567890123456789012345678901234567890 // Mock RWA Stock
RWA_BOND_ADDRESS = 0x0987654321098765432109876543210987654321  // Mock RWA Bond
LP_TOKEN_ADDRESS = 0xabCDEF1234567890ABcDEF1234567890aBCDeF12  // Mock LP Token
```

## Testing Results Interpretation

### Risk Score Calculation
Risk scores are calculated as weighted averages:
- 100% Stablecoin = Risk Score 1
- 100% Crypto = Risk Score 7
- Mixed portfolios = Proportional risk based on allocation

### Allocation Validation
- All allocations must sum to exactly 100% (10,000 basis points)
- Each asset must have valid min ≤ target ≤ max percentages
- Token addresses cannot be zero address

### Plan Management
- Plans are assigned incremental IDs starting from 1
- All plans are active by default
- Plans can be updated with new allocations
- View functions return all plan details including allocations

## Building and Compilation

The project uses Foundry with IR pipeline enabled for complex struct operations:

```bash
# Build all contracts
forge build

# Run basic tests (if any)
forge test

# Check compilation without broadcast
forge script script/DeployPlanManager.s.sol
```

## Troubleshooting

1. **Connection refused**: Make sure Anvil is running on port 8545
2. **Compilation errors**: Ensure `via_ir = true` is set in foundry.toml
3. **Invalid checksum**: All addresses in scripts are properly checksummed
4. **Gas estimation**: Scripts include gas estimation for deployment costs

## Next Steps

After testing PlanManager functionality, you can:
1. Test integration with InvestmentEngine (when implemented)
2. Add more complex allocation scenarios
3. Test with real token addresses on testnets
4. Implement additional plan types or custom risk factors