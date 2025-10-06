
# DIP: Decentralized Investment Platform

**Building habitual wealth through equitable access to decentralized finance**

A comprehensive DeFi investment platform that enables **subscription-based automated investing** with recurring contributions to diversified portfolios. Features **fair investment processing**, **real-time price feeds**, and **anti-MEV protection** powered by cutting-edge oracle technology.

## 🌟 Project Overview

DIP (Decentralized Investment Platform) bridges traditional finance with DeFi, offering **subscription-based investment plans** that automate habitual wealth building through tokenized assets. Users can subscribe to investment strategies while ensuring equal access through **Pyth Entropy's fair ordering system**. Our platform democratizes investment opportunities by providing institutional-grade tools to everyday users.

### Core Mission
- **Subscription-Based Investing**: Automated recurring investments through subscription plans
- **Habitual Wealth Building**: Encourage consistent investment practices for long-term growth
- **Financial Inclusion**: Break down barriers to investment for all income levels
- **Fair Access**: Eliminate MEV and front-running through cryptographic randomness
- **Real-Time Accuracy**: Leverage enterprise-grade price feeds for optimal execution
- **Simplified DeFi**: One-click diversified portfolio creation

## 🏗️ Architecture

### Smart Contracts
- **`PlanManager.sol`**: Investment strategy management with risk-based allocations
- **`InvestmentEngineV3.sol`**: Core engine with dual execution modes:
  - **Normal Mode**: Instant investment execution
  - **Fair Mode**: Queue-based randomized execution using Pyth Entropy
- **Mock Contracts**: Comprehensive testing infrastructure

### API Layer
- **RESTful API**: Complete investment lifecycle management
- **Real-time Price Feeds**: Pyth Hermes integration
- **Portfolio Analytics**: Performance tracking and reporting

## 🚀 Key Features

### ⚡ Pyth Network Integration

#### 🔮 **Pyth Entropy - Fair Investment Processing**
- **Anti-MEV Protection**: Prevents front-running and sandwich attacks
- **Cryptographic Randomness**: Secure commit-reveal protocol
- **Fair Execution Order**: Randomized transaction processing
- **Permissionless**: Anyone can trigger batch execution
- **Optional Feature**: Maintains backward compatibility

**Benefits:**
- Equal access for all users regardless of gas fees
- Eliminates trader advantages through timing manipulation
- Cryptographically secure random ordering
- First DeFi platform with built-in fairness guarantees
- Promotes consistent investment habits through fair processing

#### 📊 **Pyth Hermes - Real-Time Price Feeds**
- **Sub-second Updates**: Millisecond-fresh price data
- **High Fidelity**: Direct from exchanges and market makers
- **Confidence Intervals**: Built-in data quality metrics
- **Multi-Asset Support**: Crypto, stocks, commodities, forex

**Benefits:**
- Most accurate prices available in DeFi
- Reduces slippage and execution costs
- Professional-grade data reliability
- Seamless API integration

#### 🔄 **Traditional Pyth Oracle Workflow**
- **Pull-Based Pattern**: Fetch → Update → Consume
- **On-Chain Price Updates**: `updatePriceFeeds()` method
- **Staleness Protection**: `getPriceNoOlderThan()` safeguards
- **Fee Management**: Automatic fee calculation and refunds

**Benefits:**
- Guaranteed fresh prices for critical operations
- Transparent on-chain price verification
- Professional oracle integration pattern
- Cost-efficient batch price updates

### 💰 PyUSD Integration

**Why PyUSD?**
- **Regulatory Clarity**: Fully compliant US dollar stablecoin
- **Institutional Trust**: Backed by PayPal's reputation
- **Broad Adoption**: Growing ecosystem support
- **Stability**: Reliable peg to USD for consistent valuations

**Use Cases:**
- Base currency for all habitual investments
- Fiat on/off ramp for traditional users
- Stable unit of account for portfolio tracking
- Bridge between traditional and digital assets
- Consistent value measurement for recurring contributions

### 🔄 Uniswap V3 Integration

**Benefits:**
- **Capital Efficiency**: Concentrated liquidity for better prices
- **Low Slippage**: Optimized routing for minimal price impact
- **Deep Liquidity**: Access to largest DEX ecosystem
- **Flexible Fees**: Multiple fee tiers for different strategies

**Features:**
- Automated token swapping
- Slippage protection
- Failed transaction handling
- Multi-hop routing support

## 📅 Subscription-Based Investment Model

### Automated Wealth Building
DIP revolutionizes DeFi investing through **subscription-based automation**. Users can set up recurring investment plans that execute automatically, creating consistent wealth-building habits without manual intervention.

### Subscription Features
- **Flexible Intervals**: Daily, weekly, bi-weekly, or monthly investments
- **Dollar-Cost Averaging**: Reduce market timing risk through consistent investing
- **Auto-Execution**: Smart contracts handle all recurring transactions
- **Pause/Resume**: Full control over subscription lifecycle
- **Portfolio Rebalancing**: Automatic rebalancing within subscription cycles
- **Gas Optimization**: Batched transactions for cost efficiency

### Subscription Benefits
- **Habit Formation**: Builds consistent investment discipline
- **Reduced Volatility**: DCA smooths out market fluctuations
- **Time Efficiency**: Set-and-forget investment strategy
- **Compound Growth**: Regular contributions maximize compound returns
- **Behavioral Finance**: Removes emotional decision-making from investing

### How Subscriptions Work
1. **Choose Plan**: Select from pre-built or create custom allocation
2. **Set Schedule**: Define investment frequency and amount
3. **Enable Auto-Pay**: Authorize recurring token transfers
4. **Monitor Progress**: Track performance through dashboard
5. **Adjust Anytime**: Modify, pause, or cancel subscriptions

## 🎯 Investment Strategies & Subscription Plans

### Pre-Built Subscription Plans
- **Conservative Plan**: 70% Stablecoins, 20% ETH, 10% BTC
  - Monthly/Weekly/Daily subscription options
  - Low-risk automated investing
- **Balanced Plan**: 40% Stablecoins, 40% ETH, 20% BTC
  - Flexible subscription intervals
  - Moderate risk with diversification
- **Aggressive Plan**: 20% Stablecoins, 50% ETH, 30% BTC
  - High-growth subscription model
  - Advanced risk tolerance

### Custom Subscription Plans
- **Personalized Allocations**: Risk-based portfolio customization
- **Flexible Intervals**: Daily, weekly, monthly subscriptions
- **Dollar-Cost Averaging**: Automated recurring investments
- **Auto-Rebalancing**: Triggered rebalancing within subscriptions
- **Pause/Resume**: Full subscription management control

## 🛡️ Fair Investment Processing

### Traditional Problems
- **MEV Attacks**: Bots extract value from regular users
- **Front-Running**: Wealthy users get better prices
- **Gas Wars**: High fees exclude smaller investors
- **Timing Manipulation**: Technical advantages create unfair access

### Our Solution: Pyth Entropy
```solidity
// Queue investment for fair processing
function queueInvestment(
    uint256 amount,
    uint256 planId,
    bytes32 userRandomNumber
) external returns (uint256 queueId)

// Execute batch with randomized order
function executeQueuedInvestments(
    uint256[] calldata queueIds,
    bytes32 executionRandom
) external returns (uint256[] memory investmentIds)
```

### Fairness Guarantees
1. **Commit-Reveal Protocol**: Cryptographically secure randomness
2. **Fisher-Yates Shuffle**: Mathematically fair ordering
3. **Batch Processing**: Equal treatment within execution windows
4. **Transparent Process**: All randomization is on-chain and verifiable

## 📈 Real-Time Price Accuracy

### Pyth Hermes API Integration
```javascript
// Hermes API - Direct price fetching
const price = await pythHermesService.getAssetPrice('WETH');
// Returns: { price: "401280000000", formattedPrice: "$4012.80", confidence: "135185289" }

// Traditional Oracle Workflow
// Step 1: Fetch price updates from Hermes
const updates = await pythOracleService.fetchPriceUpdates(['WETH', 'WBTC']);

// Step 2: Update prices on-chain
const receipt = await pythOracleService.updatePricesOnChain(signer, updates.priceUpdateData);

// Step 3: Read updated prices from on-chain oracle
const onChainPrice = await pythOracleService.readOnChainPrice('WETH', 60);
```

### Price Feed Benefits
- **Institutional Grade**: Same feeds used by professional traders
- **Global Coverage**: 400+ price feeds across all asset classes
- **High Frequency**: Updates every 400ms
- **Confidence Intervals**: Built-in data quality metrics

## 🔧 Technology Stack

### Blockchain
- **Solidity**: Smart contract development
- **Foundry**: Testing and deployment framework
- **OpenZeppelin**: Security-audited contract libraries

### Backend
- **Node.js**: API server
- **Express**: RESTful API framework
- **Ethers.js**: Blockchain interaction

### Oracle Integration
- **Pyth Network**: Price feeds and entropy
- **Hermes Client**: Real-time price fetching
- **Entropy SDK**: Cryptographic randomness

### DEX Integration
- **Uniswap V3**: Decentralized token swapping
- **Router Integration**: Optimized trade execution

## 🚀 Getting Started

### Prerequisites
```bash
# Install dependencies
npm install
cd solidity && forge install
```

### Environment Setup
```bash
# Copy environment files
cp api/.env.example api/.env
cp solidity/.env.example solidity/.env

# Configure your network settings
edit api/.env  # Add RPC URLs and contract addresses
```

### Deploy Contracts
```bash
cd solidity
forge build
forge script script/DeployV3.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL
```

### Start API Server
```bash
cd api
npm start
# Server runs on http://localhost:3000
```

### Test Pyth Integration
```bash
# Test real-time price feeds (Hermes)
curl http://localhost:3000/api/v3/price/WETH
# Returns live ETH price from Pyth Network

# Test traditional oracle workflow
curl http://localhost:3000/api/v3/oracle/price-updates/WETH,WBTC
# Returns price update data for on-chain updates

curl http://localhost:3000/api/v3/oracle/on-chain-price/WETH?maxAge=60
# Returns on-chain oracle price (max 60 seconds old)

# Test Entropy fair processing
curl -X POST http://localhost:3000/api/v3/queue-investment \
  -H "Content-Type: application/json" \
  -d '{"amount": "1000000000", "planId": 1}'

# Test subscription creation
curl -X POST http://localhost:3000/api/v3/subscriptions \
  -H "Content-Type: application/json" \
  -d '{"planId": 1, "amount": "100000000", "interval": "weekly"}'
```

## 🧪 Testing

### Smart Contract Tests
```bash
cd solidity
forge test -vv

# Test Entropy features separately
forge test --match-test "test_Entropy" -vv
```

### API Tests
```bash
cd api
npm test
```

### Demo Script
```bash
# Run comprehensive demonstration
forge script script/DemoEntropy.s.sol --broadcast
```

## 📊 API Endpoints

### Investment Operations
- `POST /api/v3/invest` - Execute immediate investment
- `POST /api/v3/queue-investment` - Queue for fair processing
- `GET /api/v3/investment/:id` - Get investment details

### Subscription Management
- `POST /api/v3/subscriptions` - Create subscription plan
- `GET /api/v3/subscriptions/:user` - View user subscriptions
- `PUT /api/v3/subscriptions/:id` - Update subscription settings
- `DELETE /api/v3/subscriptions/:id` - Cancel subscription
- `POST /api/v3/subscriptions/:id/pause` - Pause subscription
- `POST /api/v3/subscriptions/:id/resume` - Resume subscription

### Price Feeds
- `GET /api/v3/price/:token` - Get real-time price (Hermes)
- `GET /api/v3/prices/multiple` - Batch price fetching (Hermes)

### Traditional Oracle Workflow
- `GET /api/v3/oracle/price-updates/:symbols` - Fetch price updates from Hermes
- `POST /api/v3/oracle/calculate-fee` - Calculate update fee
- `GET /api/v3/oracle/on-chain-price/:symbol` - Read on-chain oracle price
- `GET /api/v3/oracle/health` - Oracle service health check
- `POST /api/v3/invest-with-price-update` - Invest with fresh price updates

### Plans
- `GET /api/v3/plans` - List available plans
- `POST /api/v3/plans` - Create custom plan

### Analytics
- `GET /api/v3/portfolio/:user` - Portfolio overview
- `GET /api/v3/performance/:user` - Performance metrics

## 🎖️ Hackathon Innovations

### Pyth Network Features
1. **First DeFi Platform** with Pyth Entropy integration
2. **Fair Investment Processing** eliminates MEV
3. **Real-Time Price Feeds** via Hermes API
4. **Institutional-Grade Data** for retail users

### Subscription Innovation
1. **Automated DCA Engine** with subscription management
2. **Gas-Optimized Recurring Transactions** for cost efficiency
3. **Behavioral Finance Integration** promoting consistent investing
4. **Flexible Subscription Controls** with pause/resume functionality

### Novel Implementations
- **Subscription Investment Model**: Automated recurring investment plans
- **Dual Execution Modes**: Normal and fair processing
- **Cryptographic Fairness**: Provably random ordering
- **Anti-MEV Architecture**: Built-in protection mechanisms
- **Dollar-Cost Averaging Engine**: Built-in DCA through subscriptions
- **Seamless Integration**: Optional features without breaking changes
- **Seamless Integration**: Optional features without breaking changes

## 🔮 Future Roadmap

### Phase 1: Enhanced Features
- Advanced rebalancing strategies
- Multi-chain deployment

### Phase 2: Enhanced Subscription Features
- **Advanced Subscription Models**: Weekly, bi-weekly, monthly plans
- **Smart DCA Engine**: Optimized dollar-cost averaging algorithms
- **Subscription Analytics**: Performance tracking per subscription
- **Multi-Asset Subscriptions**: Tokenized stocks, bonds, and commodities
- **Employer Integration**: Payroll-deducted investment subscriptions

### Phase 3: Institutional Features
- KYC/AML compliance
- Institutional dashboards
- Regulatory reporting

## 🤝 Contributing

We welcome contributions! Please check our contributing guidelines and open an issue or submit a PR.

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🏆 Acknowledgments

- **Pyth Network**: For revolutionary oracle infrastructure
- **Uniswap Labs**: For decentralized exchange protocol
- **PayPal**: For PyUSD stablecoin innovation
- **ETHGlobal**: For fostering innovation in DeFi

---

**Built with ❤️ for financial inclusion and fairness in DeFi**

*Building wealth through automated subscription investing, one recurring contribution at a time.*
