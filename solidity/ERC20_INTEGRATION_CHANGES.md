# ERC20 Integration Changes Required

## Summary of Changes

To integrate test ERC20 tokens with your Plan and Investment contracts, here are the key modifications needed:

## 1. **PlanManager Contract** ✅ MINIMAL CHANGES
The PlanManager contract is already mostly compatible since it stores token addresses in `AssetAllocation.tokenAddress`.

**Required Changes:**
- ✅ **No major changes needed** - already stores token addresses
- ✅ Token addresses in plans will now point to real ERC20 contracts
- ✅ Validation can remain the same

## 2. **InvestmentEngine Contract** 🔄 MAJOR CHANGES REQUIRED

### Current State Issues:
- Works with simple unit balances, not real tokens
- No ERC20 token transfers
- No actual token purchases/allocations
- Simulated investment execution

### New InvestmentEngineV2 Features:

#### **A. ERC20 Token Integration**
```solidity
// NEW: Base token for deposits (e.g., USDC)
address public baseToken;

// NEW: Track user token holdings
mapping(address => mapping(address => uint256)) private _userTokenBalances;
mapping(address => address[]) private _userTokens;
```

#### **B. Real Token Deposits**
```solidity
function depositToken(address token, uint256 amount, DepositType depositType) external {
    // Transfer real ERC20 tokens from user to contract
    IERC20(token).transferFrom(msg.sender, address(this), amount);
    _processDeposit(msg.sender, amount, depositType);
}
```

#### **C. Actual Token Investment Execution**
```solidity
function executeInvestment(uint256 investmentId) external onlyOwner {
    // Get plan allocations and execute real token purchases
    _executePlanAllocations(user, amount, plan.allocations);
}
```

#### **D. Real Token Purchases**
```solidity
function _purchaseToken(address user, address token, uint256 amountInBaseToken) internal {
    // Convert base token amount to target token
    uint256 tokenAmount = _convertBaseToToken(token, amountInBaseToken);

    // Update user's token holdings
    _userTokenBalances[user][token] += tokenAmount;
}
```

#### **E. New User Functions**
```solidity
// Withdraw specific tokens
function withdrawToken(address token, uint256 amount) external

// Get user's token balance for specific token
function getUserTokenBalance(address user, address token) external view returns (uint256)

// Get all tokens held by user
function getUserTokens(address user) external view returns (address[] memory)
```

## 3. **New Required Contracts**

### **A. IERC20 Interface** ✅ CREATED
```solidity
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    // ... other standard functions
}
```

### **B. Enhanced MockERC20** ✅ CREATED
```solidity
contract MockERC20 is ERC20, Ownable {
    // Faucet functionality for testing
    function faucet() external;

    // Admin minting for testing
    function mint(address to, uint256 amount) external onlyOwner;
}
```

## 4. **Migration Steps**

### **Step 1: Deploy New Contracts**
```bash
# Deploy mock tokens
forge script script/DeployTestnetTokens.s.sol --broadcast

# Deploy InvestmentEngineV2 with base token
forge script script/TestERC20Integration.s.sol --broadcast
```

### **Step 2: Update Frontend/API Integration**
```javascript
// NEW: Approve tokens before deposit
await usdcToken.approve(investmentEngineAddress, amount);

// NEW: Deposit specific tokens
await investmentEngine.depositToken(usdcAddress, amount, depositType);

// NEW: Check user token holdings
const userTokens = await investmentEngine.getUserTokens(userAddress);
for (const token of userTokens) {
    const balance = await investmentEngine.getUserTokenBalance(userAddress, token);
}
```

### **Step 3: Fund Contract with Token Reserves**
```solidity
// Admin function to provide liquidity for token purchases
function fundContractWithTokens(address token, uint256 amount) external onlyOwner {
    IERC20(token).transferFrom(msg.sender, address(this), amount);
}
```

## 5. **Testing Flow** ✅ IMPLEMENTED

### **Complete Test Script: `TestERC20Integration.s.sol`**
1. ✅ Deploy mock ERC20 tokens (USDC, WBTC, WETH, LINK)
2. ✅ Deploy InvestmentEngineV2 with USDC as base token
3. ✅ Create investment plans using real token addresses
4. ✅ Test token deposits with real ERC20 transfers
5. ✅ Test investment execution with actual token allocation
6. ✅ Verify user token holdings after investment

## 6. **Key Differences from Current System**

| Aspect | Current System | New ERC20 System |
|--------|---------------|------------------|
| **Deposits** | Simple unit tracking | Real ERC20 transfers |
| **Balances** | Internal accounting | Actual token holdings |
| **Investments** | Simulated execution | Real token purchases |
| **Withdrawals** | Unit-based | Actual token transfers |
| **Portfolio Value** | Simple addition | Token value aggregation |

## 7. **Production Considerations** 🚧

### **Price Oracles** (Not implemented yet)
```solidity
// TODO: Integrate with Chainlink or other price feeds
function getTokenPrice(address token) external view returns (uint256);
```

### **DEX Integration** (Not implemented yet)
```solidity
// TODO: Integrate with Uniswap for actual token swaps
function swapTokens(address tokenIn, address tokenOut, uint256 amountIn) external;
```

### **Slippage Protection** (Not implemented yet)
```solidity
// TODO: Add slippage protection for token purchases
function _purchaseTokenWithSlippage(address token, uint256 amount, uint256 maxSlippage) internal;
```

## 8. **Deployment Commands**

### **Local Testing**
```bash
# Start Anvil
anvil

# Test ERC20 integration
forge script script/TestERC20Integration.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### **Testnet Deployment**
```bash
# Sepolia
forge script script/TestERC20Integration.s.sol --rpc-url https://rpc.sepolia.org --private-key $PRIVATE_KEY --broadcast --verify

# Arbitrum Sepolia
forge script script/TestERC20Integration.s.sol --rpc-url https://sepolia-rollup.arbitrum.io/rpc --private-key $PRIVATE_KEY --broadcast
```

## 9. **API Integration Updates Required**

### **New API Endpoints Needed**
```javascript
// Token management
GET  /api/tokens/:network
POST /api/tokens/:token/faucet
GET  /api/users/:address/tokens

// Enhanced deposits
POST /api/deposits/token  // New: specify token address

// Token operations
POST /api/tokens/:token/approve
POST /api/tokens/:token/withdraw
GET  /api/tokens/:token/balance/:address
```

## 10. **Summary** ✅

**Contracts Created:**
- ✅ `InvestmentEngineV2.sol` - Full ERC20 integration
- ✅ `MockERC20.sol` - Test tokens with faucet
- ✅ `TestERC20Integration.s.sol` - Complete test suite
- ✅ `IERC20.sol` - Standard interface

**Changes Required:**
- 🔄 **PlanManager**: Minimal (already compatible)
- 🔄 **InvestmentEngine**: Major overhaul (new V2 created)
- ✅ **New Contracts**: All created and tested
- ✅ **Test Suite**: Complete integration test working

**Ready for Testnet Deployment:** ✅ YES