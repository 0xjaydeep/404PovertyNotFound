// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockPyUSD} from "../src/test/MockPyUSD.sol";

contract DeployMockTokens is Script {
    function run() public {
        vm.startBroadcast();

        // Deploy mock PyUSD
        MockPyUSD mockPyUSD = new MockPyUSD();
        console.log("Mock PyUSD deployed at:", address(mockPyUSD));

        // Mint initial supply
        mockPyUSD.mint(msg.sender, 1_000_000 * 10**18); // 1 million tokens
        console.log("Minted 1,000,000 mock PyUSD to:", msg.sender);

        vm.stopBroadcast();
    }
}