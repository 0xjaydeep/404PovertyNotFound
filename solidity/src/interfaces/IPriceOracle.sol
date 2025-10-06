// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

interface IPriceOracle {
    enum AssetClass {
        Crypto,
        RWA,
        Liquidity,
        Stablecoin
    }

    // Events
    event PriceUpdated(bytes32 indexed feedId, int64 price, uint timestamp);
    event OraclePriceRequested(address indexed user, AssetClass assetClass);

    function getAssetPrice(
        AssetClass assetClass,
        bytes[] calldata priceUpdate
    ) external payable returns (int64 price);

    function getBTCPrice(
        bytes[] calldata priceUpdate
    ) external payable returns (int64 price);

    function getETHPrice(
        bytes[] calldata priceUpdate
    ) external payable returns (int64 price);

    function getCachedAssetPrice(
        AssetClass assetClass
    ) external view returns (PythStructs.Price memory price);

    function getUpdateFee(
        bytes[] calldata priceUpdate
    ) external view returns (uint fee);

    function calculateUSDValue(
        AssetClass assetClass,
        uint256 tokenAmount,
        bytes[] calldata priceUpdate
    ) external payable returns (uint256 usdValue);

    function getMultipleAssetPrices(
        AssetClass[] calldata assetClasses,
        bytes[] calldata priceUpdate
    ) external payable returns (int64[] memory prices);
}
