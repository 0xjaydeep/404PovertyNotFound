const { HermesClient } = require('@pythnetwork/hermes-client');
const { ethers } = require('ethers');

/**
 * Traditional Pyth Oracle Workflow Service
 * Implements the pull-based oracle pattern: Fetch from Hermes → Update On-chain → Consume
 */
class PythOracleService {
    constructor(providerUrl, pythContractAddress) {
        this.hermesClient = new HermesClient('https://hermes.pyth.network');
        this.provider = new ethers.JsonRpcProvider(providerUrl);
        this.pythContractAddress = pythContractAddress;

        // Pyth contract ABI for updatePriceFeeds and getUpdateFee
        this.pythAbi = [
            "function updatePriceFeeds(bytes[] calldata priceUpdateData) external payable",
            "function getUpdateFee(bytes[] calldata priceUpdateData) external view returns (uint)",
            "function getPrice(bytes32 id) external view returns (tuple(int64 price, uint64 conf, int32 expo, uint publishTime))",
            "function getPriceNoOlderThan(bytes32 id, uint age) external view returns (tuple(int64 price, uint64 conf, int32 expo, uint publishTime))"
        ];

        // Asset price feed IDs
        this.priceFeeds = {
            WETH: '0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace',
            WBTC: '0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43',
            LINK: '0x8ac0c70fff57e9aefdf5edf44b51d62c2d433653cbb2cf5cc06bb115af04d221',
            USDC: '0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a',
            PYUSD: '0xc1da76235f64b635b813a174fd33c86363732834a2ead6079d7cda42f6e76692'
        };

        this.cache = new Map();
        this.cacheTimeout = 30000; // 30 seconds
    }

    /**
     * Step 1: Fetch price update data from Hermes
     * @param {string[]} symbols - Array of asset symbols
     * @returns {Promise<Object>} Price update data and metadata
     */
    async fetchPriceUpdates(symbols) {
        try {
            const priceIds = symbols.map(symbol => {
                const priceId = this.priceFeeds[symbol.toUpperCase()];
                if (!priceId) {
                    throw new Error(`Unsupported asset symbol: ${symbol}`);
                }
                return priceId;
            });

            console.log(`Fetching price updates for: ${symbols.join(', ')}`);

            // Fetch VAA (Verifiable Action Approval) data from Hermes
            const priceUpdates = await this.hermesClient.getLatestPriceUpdates(priceIds);

            if (!priceUpdates || priceUpdates.length === 0) {
                throw new Error('No price updates available from Hermes');
            }

            // Extract the binary price update data
            const priceUpdateData = priceUpdates.map(update => {
                if (update.binary && update.binary.data) {
                    return '0x' + Buffer.from(update.binary.data, 'hex').toString('hex');
                } else {
                    throw new Error('Invalid price update format from Hermes');
                }
            });

            return {
                priceUpdateData,
                symbols,
                priceIds,
                timestamp: Date.now(),
                count: priceUpdateData.length
            };
        } catch (error) {
            console.error('Error fetching price updates from Hermes:', error);
            throw new Error(`Failed to fetch price updates: ${error.message}`);
        }
    }

    /**
     * Step 2: Calculate update fee required for on-chain update
     * @param {string[]} priceUpdateData - Binary price update data
     * @returns {Promise<string>} Fee amount in wei
     */
    async calculateUpdateFee(priceUpdateData) {
        try {
            const pythContract = new ethers.Contract(
                this.pythContractAddress,
                this.pythAbi,
                this.provider
            );

            const fee = await pythContract.getUpdateFee(priceUpdateData);
            return fee.toString();
        } catch (error) {
            console.error('Error calculating update fee:', error);
            throw new Error(`Failed to calculate update fee: ${error.message}`);
        }
    }

    /**
     * Step 3: Update prices on-chain (requires a wallet/signer)
     * @param {ethers.Signer} signer - Wallet signer
     * @param {string[]} priceUpdateData - Binary price update data
     * @returns {Promise<Object>} Transaction receipt
     */
    async updatePricesOnChain(signer, priceUpdateData) {
        try {
            const pythContract = new ethers.Contract(
                this.pythContractAddress,
                this.pythAbi,
                signer
            );

            // Get required fee
            const fee = await pythContract.getUpdateFee(priceUpdateData);

            console.log(`Updating ${priceUpdateData.length} price feeds on-chain with fee: ${ethers.formatEther(fee)} ETH`);

            // Submit transaction
            const tx = await pythContract.updatePriceFeeds(priceUpdateData, {
                value: fee
            });

            console.log(`Transaction submitted: ${tx.hash}`);

            // Wait for confirmation
            const receipt = await tx.wait();

            console.log(`Price update confirmed in block: ${receipt.blockNumber}`);

            return {
                transactionHash: receipt.hash,
                blockNumber: receipt.blockNumber,
                gasUsed: receipt.gasUsed.toString(),
                effectiveGasPrice: receipt.effectiveGasPrice.toString(),
                fee: fee.toString(),
                priceUpdatesCount: priceUpdateData.length
            };
        } catch (error) {
            console.error('Error updating prices on-chain:', error);
            throw new Error(`Failed to update prices on-chain: ${error.message}`);
        }
    }

    /**
     * Step 4: Read updated prices from on-chain oracle
     * @param {string} symbol - Asset symbol
     * @param {number} maxAge - Maximum age in seconds (optional)
     * @returns {Promise<Object>} On-chain price data
     */
    async readOnChainPrice(symbol, maxAge = null) {
        try {
            const priceId = this.priceFeeds[symbol.toUpperCase()];
            if (!priceId) {
                throw new Error(`Unsupported asset symbol: ${symbol}`);
            }

            const pythContract = new ethers.Contract(
                this.pythContractAddress,
                this.pythAbi,
                this.provider
            );

            let priceData;
            if (maxAge !== null) {
                priceData = await pythContract.getPriceNoOlderThan(priceId, maxAge);
            } else {
                priceData = await pythContract.getPrice(priceId);
            }

            const formattedPrice = Number(priceData.price) * Math.pow(10, priceData.expo);

            return {
                symbol: symbol.toUpperCase(),
                price: priceData.price.toString(),
                formattedPrice: formattedPrice,
                formattedPriceString: `$${formattedPrice.toFixed(2)}`,
                confidence: priceData.conf.toString(),
                expo: priceData.expo,
                publishTime: Number(priceData.publishTime),
                lastUpdated: new Date(Number(priceData.publishTime) * 1000).toISOString(),
                source: 'Pyth On-Chain Oracle',
                maxAge: maxAge
            };
        } catch (error) {
            console.error(`Error reading on-chain price for ${symbol}:`, error);
            throw new Error(`Failed to read on-chain price: ${error.message}`);
        }
    }

    /**
     * Complete traditional workflow: Fetch → Update → Read
     * @param {ethers.Signer} signer - Wallet signer
     * @param {string[]} symbols - Asset symbols to update
     * @returns {Promise<Object>} Complete workflow result
     */
    async executeTraditionalWorkflow(signer, symbols) {
        try {
            console.log('=== TRADITIONAL PYTH ORACLE WORKFLOW ===');

            // Step 1: Fetch from Hermes
            console.log('Step 1: Fetching price updates from Hermes...');
            const updates = await this.fetchPriceUpdates(symbols);

            // Step 2: Update on-chain
            console.log('Step 2: Updating prices on-chain...');
            const receipt = await this.updatePricesOnChain(signer, updates.priceUpdateData);

            // Step 3: Read updated prices
            console.log('Step 3: Reading updated prices from on-chain oracle...');
            const prices = {};
            for (const symbol of symbols) {
                prices[symbol] = await this.readOnChainPrice(symbol, 60); // Max 60 seconds old
            }

            return {
                workflow: 'traditional',
                step1_fetch: {
                    success: true,
                    priceUpdatesCount: updates.count,
                    symbols: updates.symbols
                },
                step2_update: {
                    success: true,
                    transactionHash: receipt.transactionHash,
                    blockNumber: receipt.blockNumber,
                    gasUsed: receipt.gasUsed,
                    fee: receipt.fee
                },
                step3_read: {
                    success: true,
                    prices: prices
                },
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            console.error('Traditional workflow failed:', error);
            throw new Error(`Traditional workflow failed: ${error.message}`);
        }
    }

    /**
     * Get price feed ID for a symbol
     * @param {string} symbol - Asset symbol
     * @returns {string} Price feed ID
     */
    getPriceFeedId(symbol) {
        return this.priceFeeds[symbol.toUpperCase()];
    }

    /**
     * Get all supported symbols
     * @returns {string[]} Array of supported symbols
     */
    getSupportedSymbols() {
        return Object.keys(this.priceFeeds);
    }

    /**
     * Health check for the traditional oracle service
     * @returns {Promise<Object>} Service health status
     */
    async healthCheck() {
        try {
            // Test fetching price updates
            const updates = await this.fetchPriceUpdates(['WETH']);

            // Test fee calculation
            const fee = await this.calculateUpdateFee(updates.priceUpdateData);

            return {
                status: 'healthy',
                timestamp: new Date().toISOString(),
                hermesConnection: 'connected',
                providerConnection: 'connected',
                sampleUpdateFee: `${ethers.formatEther(fee)} ETH`,
                supportedAssets: this.getSupportedSymbols().length
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                timestamp: new Date().toISOString(),
                error: error.message,
                supportedAssets: this.getSupportedSymbols().length
            };
        }
    }
}

module.exports = PythOracleService;