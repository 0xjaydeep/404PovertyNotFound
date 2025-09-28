// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interfaces/IEntropy.sol";

/**
 * @title MockEntropy
 * @dev Mock implementation of Pyth Entropy for testing
 * Simulates the commit-reveal protocol for random number generation
 */
contract MockEntropy is IEntropy {
    uint64 private _sequenceNumber;
    mapping(uint64 => bytes32) private _commitments;
    mapping(uint64 => bool) private _revealed;
    mapping(uint64 => bytes32) private _randomNumbers;

    /**
     * @dev Request a random number using commit-reveal scheme
     * @param userCommitment User's random commitment
     * @return sequenceNumber Sequence number for this request
     */
    function requestRandomNumber(bytes32 userCommitment) external returns (uint64 sequenceNumber) {
        _sequenceNumber++;
        sequenceNumber = _sequenceNumber;
        _commitments[sequenceNumber] = userCommitment;
        return sequenceNumber;
    }

    /**
     * @dev Reveal the random number using the sequence number and user's random value
     * @param sequenceNumber Sequence number from the request
     * @param userRandomness User's random value used in commitment
     * @return randomNumber The revealed random number
     */
    function revealRandomNumber(uint64 sequenceNumber, bytes32 userRandomness) external returns (bytes32 randomNumber) {
        require(_commitments[sequenceNumber] != bytes32(0), "Invalid sequence number");
        require(!_revealed[sequenceNumber], "Already revealed");

        // Verify commitment (in real Entropy, this would be keccak256(userRandomness))
        // For mock, we'll skip strict verification and generate a pseudo-random number
        bytes32 expectedCommitment = keccak256(abi.encodePacked(userRandomness));
        require(_commitments[sequenceNumber] == expectedCommitment, "Invalid commitment");

        // Generate pseudo-random number using block properties and user input
        randomNumber = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            userRandomness,
            sequenceNumber,
            msg.sender
        ));

        _revealed[sequenceNumber] = true;
        _randomNumbers[sequenceNumber] = randomNumber;

        return randomNumber;
    }

    /**
     * @dev Get the fee required for requesting a random number
     * @return fee The fee amount in wei (always 0 for mock)
     */
    function getFee() external pure returns (uint256 fee) {
        return 0; // No fee for mock
    }

    /**
     * @dev Get the latest sequence number
     * @return sequenceNumber The latest sequence number
     */
    function getLatestSequenceNumber() external view returns (uint64 sequenceNumber) {
        return _sequenceNumber;
    }

    /**
     * @dev Get a previously generated random number
     * @param sequenceNumber The sequence number to query
     * @return randomNumber The random number (if revealed)
     */
    function getRandomNumber(uint64 sequenceNumber) external view returns (bytes32 randomNumber) {
        require(_revealed[sequenceNumber], "Not yet revealed");
        return _randomNumbers[sequenceNumber];
    }

    /**
     * @dev Check if a sequence number has been revealed
     * @param sequenceNumber The sequence number to check
     * @return revealed True if revealed, false otherwise
     */
    function isRevealed(uint64 sequenceNumber) external view returns (bool revealed) {
        return _revealed[sequenceNumber];
    }

    /**
     * @dev Helper function to create a proper commitment
     * @param userRandomness The user's random value
     * @return commitment The commitment hash
     */
    function createCommitment(bytes32 userRandomness) external pure returns (bytes32 commitment) {
        return keccak256(abi.encodePacked(userRandomness));
    }
}