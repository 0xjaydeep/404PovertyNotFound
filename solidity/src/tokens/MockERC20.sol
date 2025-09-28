// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockERC20
 * @dev Mock ERC20 token for testing purposes with faucet functionality
 */
contract MockERC20 is ERC20, Ownable {
    uint8 private _decimals;
    uint256 public faucetAmount;
    mapping(address => uint256) public lastFaucetClaim;
    uint256 public faucetCooldown = 1 hours;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialSupply,
        uint256 _faucetAmount
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _decimals = decimals_;
        faucetAmount = _faucetAmount;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Faucet function - users can claim tokens once per cooldown period
     */
    function faucet() external {
        require(
            block.timestamp >= lastFaucetClaim[msg.sender] + faucetCooldown,
            "Faucet cooldown not met"
        );

        lastFaucetClaim[msg.sender] = block.timestamp;
        _mint(msg.sender, faucetAmount);
    }

    /**
     * @dev Admin function to mint tokens
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Admin function to set faucet amount
     */
    function setFaucetAmount(uint256 _faucetAmount) external onlyOwner {
        faucetAmount = _faucetAmount;
    }

    /**
     * @dev Admin function to set faucet cooldown
     */
    function setFaucetCooldown(uint256 _cooldown) external onlyOwner {
        faucetCooldown = _cooldown;
    }

    /**
     * @dev Check if user can claim from faucet
     */
    function canClaimFaucet(address user) external view returns (bool) {
        return block.timestamp >= lastFaucetClaim[user] + faucetCooldown;
    }

    /**
     * @dev Get time until next faucet claim
     */
    function timeUntilNextClaim(address user) external view returns (uint256) {
        uint256 nextClaimTime = lastFaucetClaim[user] + faucetCooldown;
        if (block.timestamp >= nextClaimTime) {
            return 0;
        }
        return nextClaimTime - block.timestamp;
    }
}