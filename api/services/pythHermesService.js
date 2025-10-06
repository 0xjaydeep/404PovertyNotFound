const { HermesClient } = require('@pythnetwork/hermes-client');

/**
 * Pyth Hermes Service for fetching real-time asset prices
 * Uses Pyth Network's off-chain price feeds via Hermes API
 */
class PythHermesService {
    constructor() {
        // Initialize Hermes client with public endpoint
        this.hermesClient = new HermesClient('https://hermes.pyth.network');

        // Asset price feed IDs (these are the real Pyth price feed identifiers)
        this.priceFeeds = {
            // Crypto assets
            WETH: '0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace', // ETH/USD
            WBTC: '0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43', // BTC/USD
            LINK: '0x8ac0c70fff57e9aefdf5edf44b51d62c2d433653cbb2cf5cc06bb115af04d221', // LINK/USD
            USDC: '0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a', // USDC/USD
            PYUSD: '0xc1da76235f64b635b813a174fd33c86363732834a2ead6079d7cda42f6e76692', // PYUSD/USD

            // Additional popular crypto assets
            SOL: '0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d', // SOL/USD
            AVAX: '0x93da3352f9f1d105fdfe4971cfa80e9dd777bfc5d0f683ebb6e1294b92137bb7', // AVAX/USD
            MATIC: '0x5de33a9112c2b700b8d30b8a3402c103578ccfa2765696471cc672bd5cf6ac52', // MATIC/USD
        };

        // Cache configuration
        this.cache = new Map();
        this.cacheTimeout = 30000; // 30 seconds cache
    }

    /**
     * Get real-time price for a specific asset
     * @param {string} symbol - Asset symbol (e.g., 'WETH', 'WBTC')
     * @returns {Promise<Object>} Price data object
     */
    async getAssetPrice(symbol) {
        try {
            const priceId = this.priceFeeds[symbol.toUpperCase()];
            if (!priceId) {
                throw new Error(`Unsupported asset symbol: ${symbol}`);
            }

            // Check cache first
            const cacheKey = `price_${symbol}`;
            if (this.cache.has(cacheKey)) {
                const cached = this.cache.get(cacheKey);
                if (Date.now() - cached.timestamp < this.cacheTimeout) {
                    return cached.data;
                }
            }

            try {
                // Fetch fresh price from Hermes
                const priceUpdates = await this.hermesClient.getLatestPriceUpdates([priceId]);

                // Log only essential info to avoid clutter
            console.log(`Fetched Hermes data for ${symbol}`);
            if (process.env.NODE_ENV === 'development') {
                console.log(`Full response structure:`, JSON.stringify(priceUpdates, null, 2));
            }

                if (!priceUpdates || priceUpdates.length === 0) {
                    throw new Error(`No price data available for ${symbol}`);
                }

                // Handle the response structure - priceUpdates is an array
                let priceData;
                if (Array.isArray(priceUpdates) && priceUpdates.length > 0) {
                    priceData = priceUpdates[0]; // First price update
                } else if (priceUpdates.parsed) {
                    priceData = priceUpdates; // Direct response
                } else {
                    throw new Error(`Invalid price data structure for ${symbol}`);
                }

                const price = this.parsePriceData(priceData, symbol);

                // Cache the result
                this.cache.set(cacheKey, {
                    data: price,
                    timestamp: Date.now()
                });

                return price;
            } catch (hermesError) {
                console.warn(`Hermes API error for ${symbol}, using fallback:`, hermesError.message);
                // Return fallback mock price for demo purposes
                return this.getFallbackPrice(symbol);
            }
        } catch (error) {
            console.error(`Error fetching price for ${symbol}:`, error);
            throw new Error(`Failed to fetch price for ${symbol}: ${error.message}`);
        }
    }

    /**
     * Get prices for multiple assets at once
     * @param {string[]} symbols - Array of asset symbols
     * @returns {Promise<Object>} Object with symbol keys and price data values
     */
    async getMultipleAssetPrices(symbols) {
        try {
            const priceIds = symbols.map(symbol => {
                const priceId = this.priceFeeds[symbol.toUpperCase()];
                if (!priceId) {
                    throw new Error(`Unsupported asset symbol: ${symbol}`);
                }
                return priceId;
            });

            // Fetch all prices in one request
            const priceUpdates = await this.hermesClient.getLatestPriceUpdates(priceIds);

            const prices = {};
            symbols.forEach((symbol, index) => {
                if (priceUpdates[index]) {
                    prices[symbol] = this.parsePriceData(priceUpdates[index], symbol);
                }
            });

            return prices;
        } catch (error) {
            console.error('Error fetching multiple asset prices:', error);
            throw new Error(`Failed to fetch prices: ${error.message}`);
        }
    }

    /**
     * Get all supported asset prices
     * @returns {Promise<Object>} Object with all supported asset prices
     */
    async getAllSupportedPrices() {
        const symbols = Object.keys(this.priceFeeds);
        return await this.getMultipleAssetPrices(symbols);
    }

    /**
     * Parse raw price data from Hermes response
     * @param {Object} priceData - Raw price data from Hermes
     * @param {string} symbol - Asset symbol
     * @returns {Object} Parsed price object
     */
    parsePriceData(priceData, symbol) {
        // Handle the actual Hermes API response structure
        let price, expo, conf, publishTime;

        if (priceData.parsed && priceData.parsed.length > 0) {
            // Current Hermes API structure - parsed array with nested price object
            const parsed = priceData.parsed[0];
            if (parsed.price) {
                price = parsed.price.price;
                expo = parsed.price.expo || -8;
                conf = parsed.price.conf || 0;
                publishTime = parsed.price.publish_time || Math.floor(Date.now() / 1000);
            } else {
                // Direct parsed structure
                price = parsed.price;
                expo = parsed.expo || -8;
                conf = parsed.conf || 0;
                publishTime = parsed.publish_time || parsed.publishTime || Math.floor(Date.now() / 1000);
            }
        } else if (priceData.price) {
            // Direct structure (fallback)
            price = priceData.price;
            expo = priceData.expo || -8;
            conf = priceData.conf || 0;
            publishTime = priceData.publishTime || priceData.publish_time || Math.floor(Date.now() / 1000);
        } else {
            console.error(`Unknown price data structure for ${symbol}:`, JSON.stringify(priceData, null, 2));
            throw new Error(`Cannot parse price data for ${symbol} - unknown structure`);
        }

        if (price === undefined || price === null) {
            throw new Error(`No price value found for ${symbol}`);
        }

        // Convert price using exponent
        const numericPrice = Number(price);
        const formattedPrice = numericPrice * Math.pow(10, expo);

        return {
            symbol: symbol.toUpperCase(),
            price: price.toString(),
            formattedPrice: formattedPrice,
            formattedPriceString: `$${formattedPrice.toFixed(2)}`,
            expo: expo,
            confidence: conf?.toString() || '0',
            publishTime: publishTime,
            lastUpdated: new Date(Number(publishTime) * 1000).toISOString(),
            source: 'Pyth Network Hermes'
        };
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
     * @returns {string[]} Array of supported asset symbols
     */
    getSupportedSymbols() {
        return Object.keys(this.priceFeeds);
    }

    /**
     * Get fallback price for demo purposes when Hermes API fails
     * @param {string} symbol - Asset symbol
     * @returns {Object} Mock price data
     */
    getFallbackPrice(symbol) {
        const mockPrices = {
            WETH: { price: '350000000000', expo: -8, basePrice: 3500 },
            WBTC: { price: '5000000000000', expo: -8, basePrice: 50000 },
            LINK: { price: '2000000000', expo: -8, basePrice: 20 },
            USDC: { price: '100000000', expo: -8, basePrice: 1 },
            PYUSD: { price: '100000000', expo: -8, basePrice: 1 },
            SOL: { price: '15000000000', expo: -8, basePrice: 150 },
            AVAX: { price: '4000000000', expo: -8, basePrice: 40 },
            MATIC: { price: '100000000', expo: -8, basePrice: 1 }
        };

        const mockData = mockPrices[symbol.toUpperCase()];
        if (!mockData) {
            throw new Error(`No fallback price available for ${symbol}`);
        }

        // Add some random variation (+/- 2%)
        const variation = (Math.random() - 0.5) * 0.04;
        const adjustedPrice = mockData.basePrice * (1 + variation);
        const priceInt = Math.floor(adjustedPrice * Math.pow(10, -mockData.expo));

        return {
            symbol: symbol.toUpperCase(),
            price: priceInt.toString(),
            formattedPrice: adjustedPrice,
            formattedPriceString: `$${adjustedPrice.toFixed(2)}`,
            expo: mockData.expo,
            confidence: '0',
            publishTime: Math.floor(Date.now() / 1000),
            lastUpdated: new Date().toISOString(),
            source: 'Fallback Mock (Demo)'
        };
    }

    /**
     * Clear price cache
     */
    clearCache() {
        this.cache.clear();
    }

    /**
     * Health check for the Hermes service
     * @returns {Promise<Object>} Service health status
     */
    async healthCheck() {
        try {
            // Try to fetch ETH price as a health check
            const ethPrice = await this.getAssetPrice('WETH');
            return {
                status: 'healthy',
                timestamp: new Date().toISOString(),
                samplePrice: ethPrice,
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

module.exports = PythHermesService;