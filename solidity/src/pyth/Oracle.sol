// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract SimpleOracle {
    IPyth public immutable pyth;

    enum AssetClass {
        Crypto,
        RWA,
        Liquidity,
        Stablecoin
    }

    bytes32 public constant BTC_USD_FEED_ID =
        0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43; // BTC/USD
    bytes32 public constant ETH_USD_FEED_ID =
        0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace; // ETH/USD
    bytes32 public constant AAPL_USD_FEED_ID =
        0x49f6b65cb1de6b10eaf75e7c03ca029c306d0357e91b5311b175084a5ad55688; // AAPL/USD

    event PriceUpdated(bytes32 indexed feedId, int64 price, uint timestamp);

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
}
