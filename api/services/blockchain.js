const { ethers } = require('ethers');

class BlockchainService {
  constructor() {
    this.provider = null;
    this.adminWallet = null;
    this.contracts = {};
    this.init();
  }

  async init() {
    try {
      // Initialize provider
      this.provider = new ethers.JsonRpcProvider(process.env.RPC_URL || 'http://127.0.0.1:8545');

      // Initialize admin wallet for executing transactions
      if (process.env.ADMIN_PRIVATE_KEY) {
        this.adminWallet = new ethers.Wallet(process.env.ADMIN_PRIVATE_KEY, this.provider);
      }

      // Load contract ABIs and addresses
      await this.loadContracts();

      console.log('✅ Blockchain service initialized');
    } catch (error) {
      console.error('❌ Error initializing blockchain service:', error);
    }
  }

  async loadContracts() {
    try {
      // Contract ABIs (simplified for demo - in production, load from build artifacts)
      const planManagerABI = [
        "function createPlan(uint8 planType, string memory name, tuple(uint8 assetClass, address tokenAddress, uint16 targetPercentage, uint16 minPercentage, uint16 maxPercentage)[] memory allocations) external returns (uint256)",
        "function getPlan(uint256 planId) external view returns (tuple(uint256 planId, uint8 planType, string name, tuple(uint8 assetClass, address tokenAddress, uint16 targetPercentage, uint16 minPercentage, uint16 maxPercentage)[] allocations, uint256 riskScore, bool isActive, uint256 createdAt, uint256 updatedAt))",
        "function getTotalPlans() external view returns (uint256)"
      ];

      const investmentEngineABI = [
        "function depositToken(address token, uint256 amount, uint8 depositType) external",
        "function invest(uint256 planId, uint256 amount) external returns (uint256)",
        "function executeInvestment(uint256 investmentId) external",
        "function getUserBalance(address user) external view returns (tuple(uint256 totalDeposited, uint256 availableBalance, uint256 totalInvested, uint256 pendingInvestment))",
        "function getUserTokenBalance(address user, address token) external view returns (uint256)",
        "function getUserTokens(address user) external view returns (address[])",
        "function getUserPortfolioValue(address user) external view returns (uint256)",
        "function getTotalValueLocked() external view returns (uint256)"
      ];

      const erc20ABI = [
        "function balanceOf(address owner) external view returns (uint256)",
        "function transfer(address to, uint256 amount) external returns (bool)",
        "function approve(address spender, uint256 amount) external returns (bool)",
        "function allowance(address owner, address spender) external view returns (uint256)",
        "function decimals() external view returns (uint8)",
        "function symbol() external view returns (string)",
        "function name() external view returns (string)"
      ];

      // Initialize contracts
      if (process.env.PLAN_MANAGER_ADDRESS) {
        this.contracts.planManager = new ethers.Contract(
          process.env.PLAN_MANAGER_ADDRESS,
          planManagerABI,
          this.provider
        );
      }

      if (process.env.INVESTMENT_ENGINE_ADDRESS) {
        this.contracts.investmentEngine = new ethers.Contract(
          process.env.INVESTMENT_ENGINE_ADDRESS,
          investmentEngineABI,
          this.provider
        );
      }

      // Token contracts
      this.contracts.tokens = {};
      if (process.env.USDC_ADDRESS) {
        this.contracts.tokens.usdc = new ethers.Contract(process.env.USDC_ADDRESS, erc20ABI, this.provider);
      }
      if (process.env.WBTC_ADDRESS) {
        this.contracts.tokens.wbtc = new ethers.Contract(process.env.WBTC_ADDRESS, erc20ABI, this.provider);
      }
      if (process.env.WETH_ADDRESS) {
        this.contracts.tokens.weth = new ethers.Contract(process.env.WETH_ADDRESS, erc20ABI, this.provider);
      }

    } catch (error) {
      console.error('Error loading contracts:', error);
    }
  }

  // Utility methods
  async getBlockNumber() {
    return await this.provider.getBlockNumber();
  }

  async getGasPrice() {
    return await this.provider.getFeeData();
  }

  formatTokenAmount(amount, decimals = 18) {
    return ethers.formatUnits(amount, decimals);
  }

  parseTokenAmount(amount, decimals = 18) {
    return ethers.parseUnits(amount.toString(), decimals);
  }

  // Contract interaction helpers
  async executeTransaction(contract, method, params = [], value = 0) {
    try {
      if (!this.adminWallet) {
        throw new Error('Admin wallet not configured');
      }

      const contractWithSigner = contract.connect(this.adminWallet);
      const tx = await contractWithSigner[method](...params, { value });
      const receipt = await tx.wait();

      return {
        success: true,
        txHash: receipt.hash,
        blockNumber: receipt.blockNumber,
        gasUsed: receipt.gasUsed.toString()
      };
    } catch (error) {
      console.error(`Error executing ${method}:`, error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  async callContract(contract, method, params = []) {
    try {
      const result = await contract[method](...params);
      return {
        success: true,
        data: result
      };
    } catch (error) {
      console.error(`Error calling ${method}:`, error);
      return {
        success: false,
        error: error.message
      };
    }
  }
}

module.exports = new BlockchainService();