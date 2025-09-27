# Pyth Oracle Integration for 404PovertyNotFound

This directory contains the complete Pyth Network oracle integration for the DeFi investment platform.

## 📁 File Structure

```
solidity/src/pyth/
├── IPyth.sol              # Pyth Network interface and data structures
├── IPriceOracle.sol       # Price oracle interface for the platform
├── PriceOracle.sol        # Main price oracle implementation
├── InvestmentOracle.sol   # Investment-specific oracle functionality
├── PriceFeeds.sol         # Library of Pyth price feed IDs
├── OracleManager.sol      # Centralized oracle management
└── README.md              # This file
```

## 🔧 Contract Overview

### 1. **IPyth.sol**

- Interface for Pyth Network contract
- Defines `PythStructs.Price` and `PythStructs.PriceFeed`
- Core functions: `updatePriceFeeds()`, `getPriceNoOlderThan()`

### 2. **IPriceOracle.sol**

- Platform's price oracle interface
- Defines asset classes: Crypto, Equity, ETF, Forex, Commodity, Bond, Index
- Functions for price retrieval and feed management

### 3. **PriceOracle.sol**

- Main oracle implementation
- Integrates with Pyth contract
- Manages price feed configurations
- Handles price updates and validation

### 4. **InvestmentOracle.sol**

- Investment-specific oracle features
- Portfolio valuation calculations
- Rebalance recommendations
- Trade validation and risk management

### 5. **PriceFeeds.sol**

- Library of Pyth price feed IDs
- Organized by asset class
- Helper functions for feed lookup

### 6. **OracleManager.sol**

- Centralized oracle management
- Authorized updater system
- Emergency controls
- Mass price update functionality

## 🚀 Key Features

### ✅ Multi-Asset Support

- **Crypto**: BTC, ETH, USDC, USDT, LINK, UNI, AAVE
- **Equities**: AAPL, TSLA, MSFT, NVDA, AMZN, GOOGL, META
- **ETFs**: SPY, QQQ, IVV, VTI
- **Commodities**: Gold (XAU), Silver (XAG), Oil (WTI)
- **Forex**: EUR/USD, GBP/USD, JPY/USD

### ✅ Investment Platform Integration

- Portfolio valuation with real-time prices
- Automated rebalancing recommendations
- Trade validation and risk controls
- Price impact protection

### ✅ Risk Management

- Price staleness validation
- Confidence interval checking
- Price deviation alerts
- Large trade monitoring

### ✅ Administrative Controls

- Multi-role access control
- Emergency stop functionality
- Feed configuration management
- Authorized updater system

## 💡 Usage Examples

### Basic Price Retrieval

```solidity
// Get BTC price
IPriceOracle.PriceData memory btcPrice = priceOracle.getPrice(PriceFeeds.BTC_USD, 300);

// Check if price is valid and recent
if (btcPrice.isValid && block.timestamp - btcPrice.publishTime <= 300) {
    uint256 formattedPrice = formatPrice(btcPrice.price, btcPrice.expo);
    // Use the price...
}
```

### Portfolio Valuation

```solidity
bytes32[] memory priceIds = new bytes32[](3);
priceIds[0] = PriceFeeds.BTC_USD;
priceIds[1] = PriceFeeds.ETH_USD;
priceIds[2] = PriceFeeds.AAPL_USD;

uint256[] memory amounts = new uint256[](3);
amounts[0] = 1e18; // 1 BTC
amounts[1] = 10e18; // 10 ETH
amounts[2] = 100e18; // 100 AAPL shares

InvestmentOracle.PortfolioValuation memory valuation =
    investmentOracle.getPortfolioValuation(priceIds, amounts, 600);
```

### Price Updates

```solidity
// Update prices (requires price update data from Hermes API)
bytes[] memory updateData = getHermesUpdateData(); // Fetch from off-chain
uint256 fee = oracleManager.getUpdateFee(updateData);

oracleManager.updatePrices{value: fee}(updateData);
```

## 🔗 Integration Points

### With PlanManager Contract

```solidity
import "./pyth/OracleManager.sol";

contract PlanManager {
    OracleManager public oracleManager;

    function calculatePortfolioValue(uint256 planId) external view returns (uint256) {
        // Use oracle to get real-time asset prices
        // Calculate total portfolio value
    }
}
```

### With Investment Engine

```solidity
import "./pyth/InvestmentOracle.sol";

contract InvestmentEngine {
    InvestmentOracle public investmentOracle;

    function executeRebalance(address user) external {
        // Check if rebalance is needed
        InvestmentOracle.RebalanceRecommendation memory rec =
            investmentOracle.checkRebalanceNeeded(...);

        if (rec.shouldRebalance) {
            // Execute rebalancing logic
        }
    }
}
```

## 🛠 Deployment Guide

### 1. Deploy Contracts

```bash
# Deploy in order:
forge create PriceOracle --constructor-args <PYTH_CONTRACT_ADDRESS>
forge create InvestmentOracle --constructor-args <PRICE_ORACLE_ADDRESS>
forge create OracleManager --constructor-args <PRICE_ORACLE_ADDRESS>
```

### 2. Configure Price Feeds

```solidity
// Add custom price feeds
oracleManager.addFeedConfig(
    "CUSTOM_TOKEN",
    0x123..., // Price feed ID
    IPriceOracle.AssetClass.Crypto,
    300,      // Heartbeat
    500,      // Deviation threshold
    false     // Not required
);
```

### 3. Set Up Price Updates

```javascript
// Off-chain price update service
const hermesClient = new HermesClient("https://hermes.pyth.network");

async function updatePrices() {
  const priceIds = await oracleManager.getAllPriceFeeds();
  const updateData = await hermesClient.getLatestPriceUpdates(priceIds);
  const fee = await oracleManager.getUpdateFee(updateData);

  await oracleManager.updatePrices(updateData, { value: fee });
}

// Update every 5 minutes
setInterval(updatePrices, 5 * 60 * 1000);
```

## 🔒 Security Considerations

### Price Validation

- Always check `isValid` flag
- Validate price age against requirements
- Monitor confidence intervals
- Implement circuit breakers for extreme movements

### Access Control

- Only authorized addresses can update prices
- Owner controls for emergency situations
- Multi-signature recommended for production

### Gas Optimization

- Batch price updates when possible
- Cache prices with reasonable staleness tolerance
- Use view functions for read operations

## 🌐 Network Addresses

### Mainnet Pyth Contracts

- **Ethereum**: `0x4305FB66699C3B2702D4d05CF36551390A4c69C6`
- **Arbitrum**: `0xff1a0f4744e8582DF1aE09D5611b887B6a12925C`
- **Polygon**: `0xff1a0f4744e8582DF1aE09D5611b887B6a12925C`

### Testnet Pyth Contracts

- **Sepolia**: `0xDd24F84d36BF92C65F92307595335bdFab5Bbd21`
- **Arbitrum Goerli**: `0x939C0e902FF5B3F7BA666Cc8F6aC75EE76d3f900`

## 📚 Additional Resources

- [Pyth Network Documentation](https://docs.pyth.network/)
- [Hermes API Reference](https://hermes.pyth.network/docs/)
- [Price Feed IDs](https://docs.pyth.network/price-feeds/price-feeds)
- [EVM Integration Guide](https://docs.pyth.network/price-feeds/use-real-time-data/evm)

## 🤝 Contributing

When adding new price feeds:

1. Add the price feed ID to `PriceFeeds.sol`
2. Update the helper functions
3. Configure the feed in `OracleManager.sol`
4. Add appropriate tests

## ⚠️ Important Notes

- **Price Feed IDs**: The IDs in `PriceFeeds.sol` are examples. Use actual Pyth feed IDs from their documentation
- **Testnet vs Mainnet**: Different price feed IDs for testnet and mainnet
- **Gas Costs**: Price updates require gas fees - optimize update frequency
- **Staleness**: Always validate price age before using in critical operations
