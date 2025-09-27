# PyUSD Integration Guide

## Overview

PyUSD integration adds automatic ETH to PyUSD conversion for stablecoin allocations in investment plans. The integration is modular, non-breaking, and completely optional.

## Architecture

### Core Components

1. **PyUSDManager.sol** - Standalone module handling all PyUSD functionality
2. **InvestmentEngine.sol** - Enhanced with single integration point
3. **Existing Interfaces** - Unchanged and fully backward compatible

### Integration Flow

```
Investment Execution → Check Plan Allocations → Convert Stablecoin Portion → Delegate to PyUSDManager
```

## Deployment Steps

### 1. Deploy PyUSDManager

```solidity
// Deploy PyUSD Manager
PyUSDManager pyusdManager = new PyUSDManager();

// Initialize with mainnet addresses
pyusdManager.initialize(
    0x6c3ea9036406852006290770BEdFcAbA0e23A0e8, // PyUSD token
    0xE592427A0AEce92De3Edee1F18E0157C05861564, // Uniswap V3 Router
    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2  // WETH
);

// Authorize InvestmentEngine to use PyUSDManager
pyusdManager.setAuthorizedCaller(investmentEngineAddress, true);
```

### 2. Connect to InvestmentEngine

```solidity
// Set PyUSD Manager in InvestmentEngine
investmentEngine.setPyUSDManager(address(pyusdManager));

// Configure settings
pyusdManager.updateSlippageTolerance(300); // 3%
```

## Usage Examples

### Creating Plans with PyUSD Allocation

```solidity
// Create plan with 30% stablecoin allocation
AssetAllocation[] memory allocations = new AssetAllocation[](2);

allocations[0] = AssetAllocation({
    assetClass: AssetClass.Stablecoin, // Triggers PyUSD conversion
    targetPercentage: 3000, // 30%
    minPercentage: 2500,
    maxPercentage: 3500,
    tokenAddress: address(0) // Keep in PyUSDManager
});

allocations[1] = AssetAllocation({
    assetClass: AssetClass.Crypto, // Regular investment
    targetPercentage: 7000, // 70%
    minPercentage: 6500,
    maxPercentage: 7500,
    tokenAddress: address(0)
});

planManager.createPlan(PlanType.Conservative, "PyUSD Plan", allocations);
```

### Investment Execution (Automatic)

```solidity
// Standard investment flow - no changes needed
investmentEngine.deposit(1 ether, DepositType.ETH);
uint256 investmentId = investmentEngine.invest(planId, 0.6 ether);

// PyUSD conversion happens automatically during execution
investmentEngine.executeInvestment(investmentId);
// → 30% (0.18 ETH) automatically converted to PyUSD
```

## Testing Scripts

### 1. Deploy and Test PyUSD Integration

```bash
# Deploy PyUSDManager and connect to InvestmentEngine
forge script script/DeployPyUSDIntegration.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### 2. Test PyUSD Conversion

```bash
# Test automatic PyUSD conversion with investment plans
forge script script/PyUSDInvestmentTest.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

## Key Features

### ✅ Non-Breaking Integration
- All existing functions work unchanged
- Optional initialization - can be deployed without PyUSD
- Graceful fallbacks if PyUSD operations fail

### ✅ Modular Design
- PyUSD functionality isolated in separate contract
- Clean separation of concerns
- Easy to upgrade or replace PyUSDManager

### ✅ Automatic Conversion
- Triggered by `AssetClass.Stablecoin` in investment plans
- Handles slippage protection and deadline management
- Emits events for tracking

### ✅ Administrative Controls
- Owner-only configuration functions
- Emergency withdraw capabilities
- Pause/unpause functionality

## View Functions

```solidity
// Check PyUSD status
bool enabled = investmentEngine.isPyUSDEnabled();
uint256 balance = investmentEngine.getPyUSDBalance();

// User allocations
uint256 userPyUSD = investmentEngine.getUserPyUSDAllocation(userAddress);
uint256 investmentPyUSD = investmentEngine.getInvestmentPyUSDAmount(investmentId);

// Conversion quotes
(uint256 expected, uint256 minimum) = investmentEngine.getPyUSDConversionQuote(1 ether);
```

## Configuration Options

```solidity
// Slippage tolerance (default 3%)
pyusdManager.updateSlippageTolerance(500); // 5%

// Emergency controls
pyusdManager.pause(); // Disable all PyUSD operations
pyusdManager.unpause(); // Re-enable

// Withdraw funds
pyusdManager.emergencyWithdrawPyUSD(amount);
```

## Integration Checklist

- [ ] Deploy PyUSDManager
- [ ] Initialize with token addresses
- [ ] Set authorized caller (InvestmentEngine)
- [ ] Connect PyUSDManager to InvestmentEngine
- [ ] Configure slippage tolerance
- [ ] Test with small amounts
- [ ] Create investment plans with stablecoin allocations
- [ ] Monitor conversion events
- [ ] Set up emergency procedures

## Events for Monitoring

```solidity
// PyUSD conversion tracking
event PyUSDPurchased(address user, uint256 investmentId, uint256 ethAmount, uint256 pyusdAmount, address caller);

// PyUSD transfers
event PyUSDTransferred(address user, uint256 investmentId, uint256 amount, address destination, address caller);
```

## Risk Considerations

1. **DEX Liquidity**: Monitor PyUSD/ETH pool liquidity
2. **Slippage**: Configure appropriate tolerance levels
3. **Gas Costs**: PyUSD conversion adds gas overhead
4. **Fallback Behavior**: Failed conversions fall back to original logic
5. **Emergency Access**: Ensure emergency withdraw procedures are tested