// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// VRF client intended to be used as a service by other contracts. This contract
// implements the Subscription method of VRF v2; the Direct method is not supported.
contract Chaos is VRFConsumerBaseV2 {
    // Required Chainlink parameters are set in the constructor. See Chainlink
    // VRF Configuration documentation for more information.
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 immutable s_subscriptionId;
    bytes32 s_keyHash;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    // How many words to request from the randomness function.
    uint32 public immutable numWords;
    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 25,000 per word is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 immutable callbackGasLimit;

    // The address that deploys the contract also performs administrative functions.
    address payable public owner;

    // The only address that is allowed to perform rolls.
    address public allowedCaller;

    // Maps requestID to address.
    mapping(uint => address) public s_requests;

    // Records all the roll results for an address. The last roll also keeps track
    // of addresses that have a roll in progress.
    mapping(address => uint[][]) public s_results;

    // Mapping of addresses to their balances from fallback function
    mapping(address => uint) balance;

    event AllowedAddressChanged(
        address indexed oldAddress,
        address indexed newAddress
    );
    event RollStarted(uint indexed requestId, address indexed roller);
    event RollFinished(uint indexed requestId, uint[] indexed result);

    constructor(
        bytes32 _gasLaneKeyHash,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        uint32 _numWords,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        owner = payable(msg.sender);

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);

        s_subscriptionId = _subscriptionId;
        s_keyHash = _gasLaneKeyHash;
        numWords = _numWords;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    // Only one address may perform rolls.
    modifier onlyAllowed() {
        require(msg.sender == allowedCaller, "Must be allowed caller.");
        _;
    }

    // Chainlink needs this for subscription authorization.
    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner.");
        _;
    }

    // Can only be called by a single address.
    function setAllowedCaller(address _allowedCaller) public onlyOwner {
        emit AllowedAddressChanged(allowedCaller, _allowedCaller);
        allowedCaller = _allowedCaller;
    }

    // Roll on behalf of another address.
    function rollDice(
        address _roller
    ) public onlyAllowed returns (uint256 requestId) {
        // Rolling account must not have a pending roll.
        require(readyToRoll(_roller), "Roll in progress.");

        // Request randomness and save the requestId
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        // Record the request id and link it to the user
        s_requests[requestId] = _roller;

        // All 0s means roll in progress
        uint[] memory rollInProgress = new uint[](numWords);
        for (uint i = 0; i < rollInProgress.length; i++) {
            rollInProgress[i] = 0;
        }

        s_results[_roller].push(rollInProgress);
        emit RollStarted(requestId, _roller);

        return requestId;
    }

    // Checks if an address is ready to roll. An address will generally be considered
    // ready unless the last roll is all 0s which indicates a roll is in progress.
    function readyToRoll(address _roller) public view returns (bool) {
        uint256[] memory recentRoll = lastRoll(_roller);

        // Never rolled before.
        if (recentRoll.length < numWords) {
            return true;
        }

        // Array with non-zero integers is a finished roll.
        for (uint i = 0; i < recentRoll.length; i++) {
            if (recentRoll[i] != 0) {
                return true;
            }
        }

        // Roll in progress.
        return false;
    }

    // Convenience function to return an address' last roll values.
    // Output:
    // [0,0,0,0,0,0] means roll in progress
    // [x,x,x,x,x,x] means last roll complete (where x is uint256)
    // []            means never rolled
    function lastRoll(address _roller) public view returns (uint256[] memory) {
        uint rollCount = s_results[_roller].length;

        if (rollCount < 1) {
            uint[] memory noRolls = new uint[](0);
            return noRolls;
        }

        uint256 lastIndex = s_results[_roller].length - 1;
        uint[] memory lastRollForRoller = s_results[_roller][lastIndex];
        return lastRollForRoller;
    }

    // Required callback for VRFConsumerBaseV2
    function fulfillRandomWords(
        uint requestId,
        uint[] memory randomWords
    ) internal override {
        address roller = s_requests[requestId];
        uint lastIndex = s_results[roller].length - 1;
        uint[] storage unfinishedRoll = s_results[roller][lastIndex];

        for (uint256 i = 0; i < randomWords.length; i++) {
            unfinishedRoll[i] = randomWords[i];
        }

        // Emitting event to signal that dice landed
        emit RollFinished(requestId, randomWords);
    }

    function rollerResults(
        address _roller,
        uint _rollIndex
    ) public view returns (uint[] memory) {
        return s_results[_roller][_rollIndex];
    }

    fallback() external payable {
        balance[msg.sender] += msg.value;
    }

    receive() external payable {
        balance[msg.sender] += msg.value;
    }
}
