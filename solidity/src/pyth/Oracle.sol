// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "../interfaces/IPriceOracle.sol";

contract SimpleOracle is IPriceOracle {
    IPyth public immutable pyth;

    bytes32 public constant BTC_USD_FEED_ID =
        0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43; // BTC/USD
    bytes32 public constant ETH_USD_FEED_ID =
        0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace; // ETH/USD
    bytes32 public constant AAPL_USD_FEED_ID =
        0x49f6b65cb1de6b10eaf75e7c03ca029c306d0357e91b5311b175084a5ad55688; // AAPL/USD

    /**
     * @param pythContract The address of the Pyth contract
     * @dev Get contract addresses from https://docs.pyth.network/price-feeds/contract-addresses/evm
     */
    constructor(address pythContract) {
        pyth = IPyth(pythContract);
    }

    /**
     * @notice Get BTC price in USD
     * @param priceUpdate The encoded data to update the contract with the latest price
     * @return price The BTC price in USD (scaled by 1e8)
     */
    function getBTCPrice(
        bytes[] calldata priceUpdate
    ) external payable returns (int64 price) {
        return _getPrice(BTC_USD_FEED_ID, priceUpdate);
    }

    /**
     * @notice Get ETH price in USD
     * @param priceUpdate The encoded data to update the contract with the latest price
     * @return price The ETH price in USD (scaled by 1e8)
     */
    function getETHPrice(
        bytes[] calldata priceUpdate
    ) external payable returns (int64 price) {
        return _getPrice(ETH_USD_FEED_ID, priceUpdate);
    }

    /**
     * @notice Get Apple stock price in USD
     * @param priceUpdate The encoded data to update the contract with the latest price
     * @return price The AAPL price in USD (scaled by 1e8)
     */
    function getAAPLPrice(
        bytes[] calldata priceUpdate
    ) external payable returns (int64 price) {
        return _getPrice(AAPL_USD_FEED_ID, priceUpdate);
    }

    /**
     * @notice Get asset price by asset class
     * @param assetClass The asset class
     * @param priceUpdate The encoded data to update the contract with the latest price
     * @return price The asset price in USD (scaled by 1e8)
     */
    function getAssetPrice(
        AssetClass assetClass,
        bytes[] calldata priceUpdate
    ) external payable returns (int64 price) {
        bytes32 feedId;

        if (assetClass == AssetClass.Crypto) {
            feedId = BTC_USD_FEED_ID;
        } else if (assetClass == AssetClass.RWA) {
            feedId = AAPL_USD_FEED_ID;
        } else {
            revert("Asset class not supported");
        }

        return _getPrice(feedId, priceUpdate);
    }

    /**
     * @notice Get cached price without updating (read-only)
     * @param assetClass The asset class to get cached price for
     * @return price The cached price data
     */
    function getCachedAssetPrice(
        AssetClass assetClass
    ) external view returns (PythStructs.Price memory price) {
        bytes32 feedId;

        if (assetClass == AssetClass.Crypto) {
            feedId = BTC_USD_FEED_ID;
        } else if (assetClass == AssetClass.RWA) {
            feedId = AAPL_USD_FEED_ID;
        } else {
            revert("Asset class not supported");
        }

        return pyth.getPriceUnsafe(feedId);
    }

    /**
     * @notice Calculate USD value for a given amount of tokens
     * @param assetClass The asset class
     * @param tokenAmount The amount of tokens (scaled by token decimals)
     * @param priceUpdate Price update data
     * @return usdValue The USD value (scaled by 1e18)
     */
    function calculateUSDValue(
        AssetClass assetClass,
        uint256 tokenAmount,
        bytes[] calldata priceUpdate
    ) external payable returns (uint256 usdValue) {
        int64 price = this.getAssetPrice{value: msg.value}(
            assetClass,
            priceUpdate
        );
        require(price > 0, "Invalid price");

        // Convert price from 1e8 to 1e18 and multiply by token amount
        // Assuming tokenAmount is in token's native decimals
        usdValue = (uint256(uint64(price)) * tokenAmount * 1e10) / 1e18;
    }

    /**
     * @notice Get multiple asset prices in a single call
     * @param assetClasses Array of asset classes to get prices for
     * @param priceUpdate Price update data
     * @return prices Array of prices corresponding to the asset classes
     */
    function getMultipleAssetPrices(
        AssetClass[] calldata assetClasses,
        bytes[] calldata priceUpdate
    ) external payable returns (int64[] memory prices) {
        prices = new int64[](assetClasses.length);

        // Update prices once for all feeds
        uint fee = pyth.getUpdateFee(priceUpdate);
        if (fee > 0) {
            pyth.updatePriceFeeds{value: fee}(priceUpdate);
        }

        // Get all prices
        for (uint i = 0; i < assetClasses.length; i++) {
            bytes32 feedId;

            if (assetClasses[i] == AssetClass.Crypto) {
                feedId = BTC_USD_FEED_ID;
            } else if (assetClasses[i] == AssetClass.RWA) {
                feedId = AAPL_USD_FEED_ID;
            } else {
                revert("Asset class not supported");
            }

            PythStructs.Price memory priceData = pyth.getPriceUnsafe(feedId);
            prices[i] = priceData.price;

            emit PriceUpdated(feedId, priceData.price, priceData.publishTime);
            emit OraclePriceRequested(msg.sender, assetClasses[i]);
        }
    }

    /**
     * @notice Get the fee required to update price feeds
     * @param priceUpdate The price update data
     * @return fee The required fee in wei
     */
    function getUpdateFee(
        bytes[] calldata priceUpdate
    ) external view returns (uint fee) {
        return pyth.getUpdateFee(priceUpdate);
    }

    /**
     * @notice Get cached price without updating (read-only)
     * @param priceFeedId The price feed ID
     * @return price The cached price data
     */
    function getCachedPrice(
        bytes32 priceFeedId
    ) external view returns (PythStructs.Price memory price) {
        return pyth.getPriceUnsafe(priceFeedId);
    }

    /**
     * @notice Internal function to get price for any feed ID
     * @param priceFeedId The price feed ID
     * @param priceUpdate The encoded data to update the contract with the latest price
     * @return price The asset price in USD (scaled by 1e8)
     */
    function _getPrice(
        bytes32 priceFeedId,
        bytes[] calldata priceUpdate
    ) internal returns (int64 price) {
        // Submit a priceUpdate to the Pyth contract to update the on-chain price.
        uint fee = pyth.getUpdateFee(priceUpdate);
        pyth.updatePriceFeeds{value: fee}(priceUpdate);

        // Read the current price from a price feed if it is less than 60 seconds old.
        PythStructs.Price memory priceData = pyth.getPriceNoOlderThan(
            priceFeedId,
            60
        );

        emit PriceUpdated(priceFeedId, priceData.price, priceData.publishTime);
        return priceData.price;
    }
}
