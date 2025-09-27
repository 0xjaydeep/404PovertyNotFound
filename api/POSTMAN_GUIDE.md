# 🚀 Postman API Testing Guide

Complete Postman setup for testing the 404 Poverty Not Found DeFi Investment Platform API.

## Quick Setup

### 1. Import Collection & Environment
1. Open Postman
2. Click "Import" → "Upload Files"
3. Import both files:
   - `postman-collection.json` (API endpoints)
   - `postman-environment.json` (environment variables)

### 2. Deploy Contracts First
```bash
cd ../solidity
forge script script/HackathonDemo.s.sol --broadcast --rpc-url local
```

### 3. Update Environment Variables
After deployment, update these variables in Postman:
- `usdcAddress`
- `wethAddress`
- `wbtcAddress`
- `planManagerAddress`
- `investmentEngineAddress`

### 4. Start API Server
```bash
cd ../api
npm install
npm run dev
```

## 📋 Collection Structure

### 🏥 Health & System
- **Health Check** - Verify API is running
- **System Info** - Detailed system information
- **API Root** - List available endpoints

### 📋 Investment Plans
- **Get All Plans** - View available investment strategies
- **Get Plan by ID** - View specific plan details
- **Create Plans** - Create Conservative/Balanced/Aggressive plans
- **Helper Endpoints** - Plan types and asset classes

### 💰 Investments & Deposits
- **Deposit USDC** - Simulate salary/bonus deposits
- **Create Investment** - Invest in specific plans
- **Execute Investment** - Process pending investments
- **Platform Stats** - TVL and metrics

### 📊 Portfolio Tracking
- **User Portfolio** - Complete portfolio overview
- **Token Balances** - Individual token holdings
- **Portfolio Analytics** - Performance metrics

### 🪙 Token Information
- **Supported Tokens** - Available tokens
- **Token Details** - Name, symbol, decimals
- **User Balances** - Token balances and allowances

### 🎯 Demo Scenarios
Pre-built scenario sequence for hackathon demos:
1. Health check
2. View investment plans
3. Salary deposit
4. Create investment
5. View portfolio
6. Analytics

## 🎭 Hackathon Demo Flow

### Perfect Demo Sequence:

1. **Start Here** 🏥
   ```
   Health Check → System Info
   ```

2. **Show Investment Options** 📋
   ```
   Get All Plans → Get Plan Types → Get Asset Classes
   ```

3. **User Journey** 💰
   ```
   Salary Deposit → Create Investment → Execute Investment
   ```

4. **Show Results** 📊
   ```
   User Portfolio → Portfolio Analytics → Platform Stats
   ```

## 🔧 Environment Variables

Update after contract deployment:

```json
{
  "baseUrl": "http://localhost:3000",
  "userAddress": "0x703d7220Ed2f488e9C36f7e9E522685Aaf092296",
  "usdcAddress": "0x...",  // ← Update this
  "wethAddress": "0x...",  // ← Update this
  "wbtcAddress": "0x...",  // ← Update this
  "planManagerAddress": "0x...",     // ← Update this
  "investmentEngineAddress": "0x..." // ← Update this
}
```

## 📱 Sample API Calls

### Create Investment Plan
```json
POST /api/plans
{
  "planType": 1,
  "name": "Balanced Crypto Portfolio",
  "allocations": [
    {
      "assetClass": 0,
      "tokenAddress": "{{wethAddress}}",
      "targetPercentage": 40,
      "minPercentage": 35,
      "maxPercentage": 45
    }
  ]
}
```

### Deposit Salary
```json
POST /api/investments/deposit
{
  "userAddress": "{{userAddress}}",
  "tokenAddress": "{{usdcAddress}}",
  "amount": "2000",
  "depositType": 0
}
```

### Create Investment
```json
POST /api/investments
{
  "userAddress": "{{userAddress}}",
  "planId": "1",
  "amount": "1000"
}
```

## 🎯 Tips for Demo

1. **Pre-test Everything** - Run the demo scenario first
2. **Use Variables** - Don't hardcode addresses
3. **Show Real Data** - Execute investments to show token allocations
4. **Highlight Features**:
   - Automated portfolio allocation
   - Real-time balance tracking
   - Multi-token support
   - Investment analytics

## 🔍 Troubleshooting

**API not responding?**
- Check if server is running (`npm run dev`)
- Verify `baseUrl` in environment

**Contract errors?**
- Ensure contracts are deployed
- Update contract addresses in environment
- Check `.env` file in API folder

**Empty responses?**
- Deploy contracts first
- Execute some deposits/investments for test data

## 🏆 Hackathon Presentation Tips

1. **Start with Health Check** - Show system is working
2. **Demonstrate User Journey** - Salary → Investment → Portfolio
3. **Show Real Numbers** - Token balances, portfolio value
4. **Highlight Automation** - Percentage-based allocation
5. **End with Analytics** - Show platform growth metrics

Perfect for impressing judges with a complete, working DeFi platform! 🚀