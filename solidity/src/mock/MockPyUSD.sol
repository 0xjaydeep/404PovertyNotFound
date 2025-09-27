// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockPyUSD is ERC20 {
    constructor() ERC20("PayPal USD", "PYUSD") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}