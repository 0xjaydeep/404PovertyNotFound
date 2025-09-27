// Contract configuration for InvestmentEngineV3 API
const { ethers } = require('ethers');

// Network configurations
const NETWORKS = {
  localhost: {
    chainId: 31337,
    name: 'Localhost',
    rpcUrl: 'http://127.0.0.1:8545',
    blockExplorer: null
  },
  sepolia: {
    chainId: 11155111,
    name: 'Sepolia',
    rpcUrl: process.env.SEPOLIA_RPC_URL || 'https://sepolia.infura.io/v3/YOUR_KEY',
    blockExplorer: 'https://sepolia.etherscan.io'
  },
  base_sepolia: {
    chainId: 84532,
    name: 'Base Sepolia',
    rpcUrl: process.env.BASE_SEPOLIA_RPC_URL || 'https://sepolia.base.org',
    blockExplorer: 'https://sepolia-explorer.base.org'
  },
  arbitrum_sepolia: {
    chainId: 421614,
    name: 'Arbitrum Sepolia',
    rpcUrl: process.env.ARBITRUM_SEPOLIA_RPC_URL || 'https://sepolia-rollup.arbitrum.io/rpc',
    blockExplorer: 'https://sepolia.arbiscan.io'
  }
};

// Contract addresses by network
const CONTRACT_ADDRESSES = {
  localhost: {
    INVESTMENT_ENGINE_V3: process.env.LOCAL_INVESTMENT_ENGINE_V3_ADDRESS,
    PLAN_MANAGER: process.env.LOCAL_PLAN_MANAGER_ADDRESS,
    UNISWAP_V4_ROUTER: process.env.LOCAL_UNISWAP_V4_ROUTER_ADDRESS,
    TOKENS: {
      USDC: process.env.LOCAL_USDC_ADDRESS,
      WETH: process.env.LOCAL_WETH_ADDRESS,
      WBTC: process.env.LOCAL_WBTC_ADDRESS,
      LINK: process.env.LOCAL_LINK_ADDRESS
    }
  },
  sepolia: {
    INVESTMENT_ENGINE_V3: process.env.SEPOLIA_INVESTMENT_ENGINE_V3_ADDRESS,
    PLAN_MANAGER: process.env.SEPOLIA_PLAN_MANAGER_ADDRESS,
    UNISWAP_V4_ROUTER: process.env.SEPOLIA_UNISWAP_V4_ROUTER_ADDRESS || '0xE592427A0AEce92De3Edee1F18E0157C05861564', // V3 Router fallback
    TOKENS: {
      USDC: process.env.SEPOLIA_USDC_ADDRESS || '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238',
      WETH: process.env.SEPOLIA_WETH_ADDRESS || '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14',
      WBTC: process.env.SEPOLIA_WBTC_ADDRESS,
      LINK: process.env.SEPOLIA_LINK_ADDRESS || '0x779877A7B0D9E8603169DdbD7836e478b4624789'
    }
  },
  base_sepolia: {
    INVESTMENT_ENGINE_V3: process.env.BASE_SEPOLIA_INVESTMENT_ENGINE_V3_ADDRESS,
    PLAN_MANAGER: process.env.BASE_SEPOLIA_PLAN_MANAGER_ADDRESS,
    UNISWAP_V4_ROUTER: process.env.BASE_SEPOLIA_UNISWAP_V4_ROUTER_ADDRESS,
    TOKENS: {
      USDC: process.env.BASE_SEPOLIA_USDC_ADDRESS,
      WETH: process.env.BASE_SEPOLIA_WETH_ADDRESS,
      WBTC: process.env.BASE_SEPOLIA_WBTC_ADDRESS,
      LINK: process.env.BASE_SEPOLIA_LINK_ADDRESS
    }
  },
  arbitrum_sepolia: {
    INVESTMENT_ENGINE_V3: process.env.ARBITRUM_SEPOLIA_INVESTMENT_ENGINE_V3_ADDRESS,
    PLAN_MANAGER: process.env.ARBITRUM_SEPOLIA_PLAN_MANAGER_ADDRESS,
    UNISWAP_V4_ROUTER: process.env.ARBITRUM_SEPOLIA_UNISWAP_V4_ROUTER_ADDRESS,
    TOKENS: {
      USDC: process.env.ARBITRUM_SEPOLIA_USDC_ADDRESS,
      WETH: process.env.ARBITRUM_SEPOLIA_WETH_ADDRESS,
      WBTC: process.env.ARBITRUM_SEPOLIA_WBTC_ADDRESS,
      LINK: process.env.ARBITRUM_SEPOLIA_LINK_ADDRESS
    }
  }
};

// Get current network configuration
const getCurrentNetwork = () => {
  const networkName = process.env.NETWORK || 'localhost';

  if (!NETWORKS[networkName]) {
    throw new Error(`Unsupported network: ${networkName}`);
  }

  return {
    ...NETWORKS[networkName],
    contracts: CONTRACT_ADDRESSES[networkName]
  };
};

// Initialize Web3 provider
const initializeProvider = () => {
  const network = getCurrentNetwork();

  if (!network.rpcUrl) {
    throw new Error(`RPC URL not configured for network: ${network.name}`);
  }

  return new ethers.JsonRpcProvider(network.rpcUrl);
};

// Contract factory functions
const createInvestmentEngineContract = (provider) => {
  const network = getCurrentNetwork();
  const address = network.contracts.INVESTMENT_ENGINE_V3;

  if (!address) {
    throw new Error(`InvestmentEngineV3 address not configured for network: ${network.name}`);
  }

  return new ethers.Contract(
    address,
    require('../abis/InvestmentEngineV3.json'),
    provider
  );
};

const createPlanManagerContract = (provider) => {
  const network = getCurrentNetwork();
  const address = network.contracts.PLAN_MANAGER;

  if (!address) {
    throw new Error(`PlanManager address not configured for network: ${network.name}`);
  }

  return new ethers.Contract(
    address,
    require('../abis/PlanManager.json'),
    provider
  );
};

const createTokenContract = (tokenSymbol, provider) => {
  const network = getCurrentNetwork();
  const address = network.contracts.TOKENS[tokenSymbol];

  if (!address) {
    throw new Error(`${tokenSymbol} address not configured for network: ${network.name}`);
  }

  return new ethers.Contract(
    address,
    require('../abis/ERC20.json'),
    provider
  );
};

// Validation functions
const validateContractAddresses = () => {
  const network = getCurrentNetwork();
  const contracts = network.contracts;

  const required = ['INVESTMENT_ENGINE_V3', 'PLAN_MANAGER'];
  const missing = required.filter(key => !contracts[key]);

  if (missing.length > 0) {
    throw new Error(`Missing contract addresses for ${network.name}: ${missing.join(', ')}`);
  }

  // Validate Ethereum addresses
  Object.entries(contracts).forEach(([key, value]) => {
    if (key === 'TOKENS') {
      Object.entries(value).forEach(([tokenKey, tokenValue]) => {
        if (tokenValue && !ethers.isAddress(tokenValue)) {
          throw new Error(`Invalid ${tokenKey} address: ${tokenValue}`);
        }
      });
    } else if (value && !ethers.isAddress(value)) {
      throw new Error(`Invalid ${key} address: ${value}`);
    }
  });
};

// Export configuration
module.exports = {
  NETWORKS,
  CONTRACT_ADDRESSES,
  getCurrentNetwork,
  initializeProvider,
  createInvestmentEngineContract,
  createPlanManagerContract,
  createTokenContract,
  validateContractAddresses
};