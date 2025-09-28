// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract MockPyth is IPyth {
    mapping(bytes32 => PythStructs.Price) public prices;

    function getPrice(bytes32 id) external view returns (PythStructs.Price memory) {
        return prices[id];
    }

    function getPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory) {
        return prices[id];
    }

    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory) {
        return prices[id];
    }

    function getEmaPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory) {
        return prices[id];
    }

    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory) {
        return prices[id];
    }

    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory) {
        return prices[id];
    }

    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256) {
        return 0;
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory _priceFeeds) {
        _priceFeeds = new PythStructs.PriceFeed[](priceIds.length);
        for (uint i = 0; i < priceIds.length; i++) {
            _priceFeeds[i] = PythStructs.PriceFeed({
                id: priceIds[i],
                price: prices[priceIds[i]],
                emaPrice: prices[priceIds[i]]
            });
        }
    }

    function updatePriceFeeds(bytes[] calldata updateData) external payable {}

    function setPrice(bytes32 id, int64 price, int32 expo) public {
        prices[id] = PythStructs.Price({
            price: price,
            conf: 0,
            expo: expo,
            publishTime: uint64(block.timestamp)
        });
    }

    function getValidTimePeriod() external view returns (uint256) {
        return 0;
    }

    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable {
        // Mock implementation: do nothing
    }
}
