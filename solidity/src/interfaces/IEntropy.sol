// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title IEntropy
 * @dev Interface for Pyth Entropy random number generation
 * This is a mock interface based on Pyth Entropy documentation
 */
interface IEntropy {
    /**
     * @dev Request a random number using commit-reveal scheme
     * @param userCommitment User's random commitment
     * @return sequenceNumber Sequence number for this request
     */
    function requestRandomNumber(bytes32 userCommitment) external returns (uint64 sequenceNumber);

    /**
     * @dev Reveal the random number using the sequence number and user's random value
     * @param sequenceNumber Sequence number from the request
     * @param userRandomness User's random value used in commitment
     * @return randomNumber The revealed random number
     */
    function revealRandomNumber(uint64 sequenceNumber, bytes32 userRandomness) external returns (bytes32 randomNumber);

    /**
     * @dev Get the fee required for requesting a random number
     * @return fee The fee amount in wei
     */
    function getFee() external view returns (uint256 fee);

    /**
     * @dev Get the latest sequence number
     * @return sequenceNumber The latest sequence number
     */
    function getLatestSequenceNumber() external view returns (uint64 sequenceNumber);
}