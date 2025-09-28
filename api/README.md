# 404 Poverty Not Found - API

Express.js API for the 404 Poverty Not Found DeFi Investment Platform.

## Quick Start

### 1. Install Dependencies
```bash
cd api
npm install
```

### 2. Configure Environment
```bash
cp .env.example .env
# Edit .env with your contract addresses and settings
```

### 3. Deploy Contracts First
```bash
cd ../solidity
forge script script/HackathonDemo.s.sol --broadcast --rpc-url local
# Copy contract addresses to API .env file
```

### 4. Start API Server
```bash
npm run dev
```

The API will be available at `http://localhost:3000`

## API Endpoints

### Health & System
- `GET /api/health` - Health check
- `GET /api/health/system` - Detailed system info

### Investment Plans
- `GET /api/plans` - Get all investment plans
- `GET /api/plans/:planId` - Get specific plan
- `POST /api/plans` - Create new plan
- `GET /api/plans/types/list` - Get plan types
- `GET /api/plans/assets/classes` - Get asset classes

### Investments
- `POST /api/investments` - Create investment
- `POST /api/investments/:id/execute` - Execute investment (admin)
- `POST /api/investments/deposit` - Deposit tokens
- `GET /api/investments/deposit-types` - Get deposit types
- `GET /api/investments/stats` - Platform statistics

### Portfolio
- `GET /api/portfolio/:userAddress` - User portfolio overview
- `GET /api/portfolio/:userAddress/tokens/:tokenAddress` - Specific token balance
- `GET /api/portfolio/:userAddress/analytics` - Portfolio analytics

### Tokens
- `GET /api/tokens` - Supported tokens
- `GET /api/tokens/:tokenAddress` - Token info
- `GET /api/tokens/:tokenAddress/balance/:userAddress` - Token balance
- `GET /api/tokens/:tokenAddress/allowance/:userAddress` - Token allowance

## Example Usage

### Create Investment Plan
```bash
curl -X POST http://localhost:3000/api/plans \
  -H "Content-Type: application/json" \
  -d '{
    "planType": 1,
    "name": "Balanced Crypto Portfolio",
    "allocations": [
      {
        "assetClass": 0,
        "tokenAddress": "0x...",
        "targetPercentage": 50,
        "minPercentage": 45,
        "maxPercentage": 55
      }
    ]
  }'
```

### Get User Portfolio
```bash
curl http://localhost:3000/api/portfolio/0x123...
```

### Deposit Tokens
```bash
curl -X POST http://localhost:3000/api/investments/deposit \
  -H "Content-Type: application/json" \
  -d '{
    "userAddress": "0x123...",
    "tokenAddress": "0x456...",
    "amount": "1000",
    "depositType": 0
  }'
```

## Environment Variables

Required variables in `.env`:

```env
# Server
PORT=3000
NODE_ENV=development

# Blockchain
RPC_URL=http://127.0.0.1:8545
CHAIN_ID=31337

# Contracts (update after deployment)
PLAN_MANAGER_ADDRESS=0x...
INVESTMENT_ENGINE_ADDRESS=0x...
USDC_ADDRESS=0x...
WBTC_ADDRESS=0x...
WETH_ADDRESS=0x...

# Admin operations
ADMIN_PRIVATE_KEY=0x...
```

## Response Format

All API responses follow this format:

```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message"
}
```

Error responses:
```json
{
  "success": false,
  "error": "Error message"
}
```

## Hackathon Demo

For quick demo purposes:

1. Run the hackathon demo script to deploy contracts
2. Copy contract addresses to `.env`
3. Start the API
4. Use the health endpoint to verify everything is working
5. Test endpoints with curl or Postman

The API is designed to be frontend-agnostic and easy to integrate with React, Vue, or any web framework.