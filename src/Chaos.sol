// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// VRF client intended to be used as a service by other contracts. This contract
// implements the Subscription method of VRF v2; the Direct method is not supported.
contract Chaos is VRFConsumerBaseV2 {
    // Required Chainlink parameters are set in the constructor. See Chainlink
    // VRF Configuration documentation for more information.
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 s_keyHash;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    // How many words to request from the randomness function.
    uint32 numWords = 6;
    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 25,000 per word is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 25000 * numWords;

    // The address that deploys the contract also performs administrative functions.
    address payable public owner;

    // The only address that is allowed to perform rolls.
    address public allowed;

    // Maps requestID to address.
    mapping(uint256 => address) internal s_requests;

    // Records all the roll results for an address. The last roll also keeps track
    // of addresses that have a roll in progress.
    mapping(address => uint256[numWords][]) private s_results;

    // Mapping of addresses to their balances from fallback function
    mapping(address => uint) balance;

    event RollStarted(uint256 indexed requestId, address indexed roller);
    event RollFinished(uint256 indexed requestId, uint256[] indexed result);

    constructor(
        bytes32 _gasLaneKeyHash,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _numWords
    ) VRFConsumerBaseV2(vrfCoordinator) {
        owner = msg.sender;

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);

        s_subscriptionId = _subscriptionId;
        s_keyHash = _gasLaneKeyHash;
        numWords = _numWords;
    }

    // Only one address may perform rolls.
    modifier onlyAllowed() {
        require(msg.sender == allowed);
        _;
    }

    // Chainlink needs this for subscription authorization.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Roll on behalf of another address.
    function rollDice(address _roller)
        public
        onlyAllowed
        returns (uint256 requestId)
    {
        // Rolling account must not have a pending roll.
        require(readyToRoll(_roller));

        // Request randomness and save the requestId
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        // Record the request id and link it to the user
        s_shipwrights[requestId] = _shipwright;

        // All 0s means roll in progress
        uint256[numWords] rollInProgress;
        for (uint i = 0; i < rollInProgress.length; i++) {
            rollInProgress[i] = 0;
        }

        s_results[_shipwright].push(rollInProgress);
        emit ShipBuild(requestId, _shipwright);
    }

    // Checks if an address is ready to roll. An address will generally be considered
    // ready unless the last roll is all 0s which indicates a roll is in progress.
    function readyToRoll(address _roller) view returns (bool) {
        uint256[numWords] memory lastRoll = lastRoll(_roller);

        bool readyToRoll = true;
        for (uint i = 0; i < lastRoll.length; i++) {
            if (lastRoll[i] != 0) {
                readyToRoll = false;
            }
        }

        return readyToRoll;
    }

    // Convenience function to return an address' last roll values.
    function lastRoll(address _roller)
        view
        returns (uint256[numWords] storage)
    {
        uint256 lastIndex = s_results[_shipwright].length - 1;
        return s_results[_shipwright][lastIndex];
    }

    // Required callback for VRFConsumerBaseV2
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        address roller = s_requests[requestId];

        uint256[numWords] storage lastRoll = lastRoll(roller);

        for (uint256 i = 0; i < lastRoll.length; i++) {
            lastRoll[i] = randomWords[i];
        }

        // emitting event to signal that dice landed
        emit ShipBuildDone(requestId, randomWords);
    }

    fallback() external payable {
        balance[msg.sender] += msg.value;
    }
}
