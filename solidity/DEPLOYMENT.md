# Deployment Guide

This guide covers deploying the 404 Poverty Not Found smart contracts to local, Unichain testnet, and Unichain mainnet networks.

## Prerequisites

1. **Install Foundry**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Setup Environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your private key and API keys
   ```

3. **Fund Your Wallet**:
   - **Local**: Anvil provides test ETH automatically
   - **Unichain Sepolia**: Get testnet ETH from faucet
   - **Unichain Mainnet**: Ensure sufficient ETH balance

## Network Configurations

### Local Network (Anvil)
- **Chain ID**: 31337
- **RPC URL**: http://127.0.0.1:8545
- **Purpose**: Development and testing

### Unichain Sepolia Testnet
- **Chain ID**: 1301
- **RPC URL**: https://1301.rpc.thirdweb.com
- **Block Explorer**: https://unichain-sepolia.blockscout.com
- **Purpose**: Testing before mainnet deployment

### Unichain Mainnet
- **Chain ID**: 130
- **RPC URL**: https://130.rpc.thirdweb.com
- **Block Explorer**: https://unichain.blockscout.com
- **Purpose**: Production deployment

## Deployment Commands

### 1. Local Deployment (Comprehensive Testing)

```bash
# Start Anvil in separate terminal
anvil

# Deploy with comprehensive test data
forge script script/DeployToLocal.s.sol --rpc-url local --broadcast

# Alternative: Deploy basic setup only
forge script script/DeployInvestmentEngine.s.sol --rpc-url local --broadcast
```

**Features of Local Deployment**:
- 7 comprehensive investment plans (Ultra Conservative to DeFi Native)
- 3 simulated user scenarios (Young Professional, Mid-Career, Pre-Retirement)
- Complete test data for immediate testing
- Low minimum deposit (100 wei) for easy testing

### 2. Unichain Sepolia Testnet Deployment

```bash
# Deploy to testnet
forge script script/DeployToUnichain.s.sol --rpc-url unichain_sepolia --broadcast --verify

# Or using private key directly
forge script script/DeployToUnichain.s.sol \
  --rpc-url https://1301.rpc.thirdweb.com \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### 3. Unichain Mainnet Deployment

```bash
# Deploy to mainnet (BE CAREFUL!)
forge script script/DeployToUnichain.s.sol --rpc-url unichain --broadcast --verify

# Or using private key directly
forge script script/DeployToUnichain.s.sol \
  --rpc-url https://130.rpc.thirdweb.com \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

## Pre-Deployment Checklist

### Security Checklist ✅
- [ ] Private keys stored securely (not in code)
- [ ] Contract audited and tested thoroughly
- [ ] All test scripts pass successfully
- [ ] Gas limits and prices reviewed
- [ ] Contract verification setup ready

### Configuration Checklist ✅
- [ ] Update token addresses for target network
- [ ] Set appropriate minimum deposit amounts
- [ ] Configure asset risk factors if needed
- [ ] Set up block explorer verification
- [ ] Prepare monitoring and alerting

### Testing Checklist ✅
- [ ] All unit tests pass: `forge test`
- [ ] Local deployment successful
- [ ] Test scripts execute without errors
- [ ] User scenarios work as expected
- [ ] View functions return correct data

## Post-Deployment Steps

### 1. Contract Verification

```bash
# Verify PlanManager
forge verify-contract [PLAN_MANAGER_ADDRESS] \
  src/PlanManager.sol:PlanManager \
  --chain-id [CHAIN_ID] \
  --constructor-args $(cast abi-encode "constructor()")

# Verify InvestmentEngine
forge verify-contract [INVESTMENT_ENGINE_ADDRESS] \
  src/InvestmentEngine.sol:InvestmentEngine \
  --chain-id [CHAIN_ID] \
  --constructor-args $(cast abi-encode "constructor()")
```

### 2. Initial Configuration

```bash
# Set minimum deposit (example: 0.01 USDC = 10000 for 6 decimals)
cast send [INVESTMENT_ENGINE_ADDRESS] \
  "setMinimumDeposit(uint256)" 10000 \
  --rpc-url [RPC_URL] \
  --private-key $PRIVATE_KEY

# Update asset risk factors if needed
cast send [PLAN_MANAGER_ADDRESS] \
  "setAssetRiskFactor(uint8,uint256)" 0 7 \
  --rpc-url [RPC_URL] \
  --private-key $PRIVATE_KEY
```

### 3. Frontend Integration

Update your frontend with deployed contract addresses:

```javascript
// Frontend configuration
const contracts = {
  planManager: "0x...", // PlanManager address
  investmentEngine: "0x...", // InvestmentEngine address
  chainId: 130, // or 1301 for testnet
  rpcUrl: "https://130.rpc.thirdweb.com"
};
```

### 4. Monitoring Setup

- Set up transaction monitoring
- Configure gas price alerts
- Monitor contract balance and activity
- Set up error notification system

## Troubleshooting

### Common Issues

1. **Insufficient Gas**:
   ```bash
   # Increase gas limit
   forge script script/DeployToUnichain.s.sol --gas-limit 10000000 --rpc-url unichain --broadcast
   ```

2. **RPC Issues**:
   ```bash
   # Try alternative RPC endpoints
   # Check foundry.toml for backup URLs
   ```

3. **Verification Failures**:
   ```bash
   # Manual verification with flattened contracts
   forge flatten src/PlanManager.sol > PlanManager.flat.sol
   # Submit to block explorer manually
   ```

4. **Transaction Nonce Issues**:
   ```bash
   # Reset nonce
   cast nonce [YOUR_ADDRESS] --rpc-url [RPC_URL]
   ```

### Network-Specific Issues

**Unichain Testnet**:
- Ensure sufficient test ETH from faucet
- Check testnet RPC endpoint availability
- Verify chain ID is correct (1301)

**Unichain Mainnet**:
- Double-check contract addresses before large deposits
- Monitor gas prices during deployment
- Ensure sufficient ETH for deployment gas

## Gas Optimization

### Deployment Gas Costs (Estimates)

| Contract | Estimated Gas | ETH Cost @ 0.1 gwei |
|----------|---------------|---------------------|
| PlanManager | ~2,570,000 | ~0.000257 ETH |
| InvestmentEngine | ~2,480,000 | ~0.000248 ETH |
| **Total** | **~5,050,000** | **~0.000505 ETH** |

### Optimization Tips

1. **Use Optimizer**:
   ```toml
   # foundry.toml
   optimizer = true
   optimizer_runs = 200
   ```

2. **Deploy in Batches**:
   - Deploy PlanManager first
   - Deploy InvestmentEngine second
   - Link contracts in separate transaction

3. **Monitor Gas Prices**:
   ```bash
   # Check current gas price
   cast gas-price --rpc-url unichain
   ```

## Emergency Procedures

### Contract Upgrade Strategy
- Contracts are not upgradeable by design
- Plan for redeployment if critical issues found
- Maintain migration scripts for user data

### Security Incident Response
1. Pause contract operations if possible
2. Notify users through official channels
3. Coordinate with security team
4. Prepare hotfix deployment if needed

## Additional Resources

- **Unichain Documentation**: https://docs.unichain.org
- **Foundry Documentation**: https://book.getfoundry.sh
- **Block Explorers**:
  - Mainnet: https://unichain.blockscout.com
  - Testnet: https://unichain-sepolia.blockscout.com

---

**⚠️ Important**: Always test thoroughly on testnet before mainnet deployment. Keep private keys secure and never commit them to version control.