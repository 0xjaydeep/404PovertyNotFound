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

    constructor(address pythContract) {
        pyth = IPyth(pythContract);
    }

    function getBTCPrice(
        bytes[] calldata priceUpdate
    ) external payable returns (int64 price) {
        return _getPrice(BTC_USD_FEED_ID, priceUpdate);
    }

    function getETHPrice(
        bytes[] calldata priceUpdate
    ) external payable returns (int64 price) {
        return _getPrice(ETH_USD_FEED_ID, priceUpdate);
    }

    function getAAPLPrice(
        bytes[] calldata priceUpdate
    ) external payable returns (int64 price) {
        return _getPrice(AAPL_USD_FEED_ID, priceUpdate);
    }

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

    function getUpdateFee(
        bytes[] calldata priceUpdate
    ) external view returns (uint fee) {
        return pyth.getUpdateFee(priceUpdate);
    }

    function getCachedPrice(
        bytes32 priceFeedId
    ) external view returns (PythStructs.Price memory price) {
        return pyth.getPriceUnsafe(priceFeedId);
    }

    function _getPrice(
        bytes32 priceFeedId,
        bytes[] calldata priceUpdate
    ) internal returns (int64 price) {
        // updating the price
        uint fee = pyth.getUpdateFee(priceUpdate);
        pyth.updatePriceFeeds{value: fee}(priceUpdate);

        // read new price if less than 60 seconds
        PythStructs.Price memory priceData = pyth.getPriceNoOlderThan(
            priceFeedId,
            60
        );

        emit PriceUpdated(priceFeedId, priceData.price, priceData.publishTime);
        return priceData.price;
    }
}