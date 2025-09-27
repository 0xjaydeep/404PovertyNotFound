// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/pyth/Oracle.sol";

contract DeploySimpleOracleUnichain is Script {
    // Pyth contract address for Unichain Sepolia testnet
    address constant PYTH_CONTRACT_UNICHAIN_SEPOLIA =
        0x2880aB155794e7179c9eE2e38200202908C17B43;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy SimpleOracle with Pyth contract address
        SimpleOracle oracle = new SimpleOracle(PYTH_CONTRACT_UNICHAIN_SEPOLIA);

        vm.stopBroadcast();

        console.log("SimpleOracle deployed to:", address(oracle));
        console.log("Pyth contract address:", PYTH_CONTRACT_UNICHAIN_SEPOLIA);
        console.log("Deployment completed on Unichain Sepolia testnet");

        // Log the price feed IDs for testing
        console.log("BTC/USD Feed ID:", vm.toString(oracle.BTC_USD_FEED_ID()));
        console.log("ETH/USD Feed ID:", vm.toString(oracle.ETH_USD_FEED_ID()));
        console.log(
            "AAPL/USD Feed ID:",
            vm.toString(oracle.AAPL_USD_FEED_ID())
        );
    }
}
