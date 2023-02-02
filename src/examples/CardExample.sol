// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ChaosFarmInterface {
    function lastRoll(address _roller) external view returns (uint[] memory);

    function readyToRoll(address _roller) external view returns (bool);

    function rollDice(address _roller) external returns (uint);

    function rollerResults(
        address _roller,
        uint _rollIndex
    ) external view returns (uint[] memory);

    function setAllowedCaller(address _allowedCaller) external;
}

// Chaos Farm provides the random values that are used to create
// a playing card. The card state exists independently from the
// random values in the VRF contract, though it references the
// VRF values for auditing / logging purposes. Note this requires
// overriding the callback to capture the roll state.
contract CardExample {
    address payable public owner;
    ChaosFarmInterface ChaosFarmContract;

    uint[] cards;
    mapping(address => uint[]) public holders;

    constructor(address _deckAddress) {
        owner = payable(msg.sender);
        ChaosFarmContract = ChaosFarmInterface(_deckAddress);
    }

    function lastCard(address _owner) public view returns (uint[] memory) {
        return ChaosFarmContract.lastRoll(_owner);
    }

    // Create a random pet for the caller.
    function requestNewCard() public returns (uint) {
        return ChaosFarmContract.rollDice(msg.sender);
    }

    function completeNewCard() public returns (uint) {
        uint[] memory roll = ChaosFarmContract.lastRoll(msg.sender);

        holders[msg.sender].push(cards.length);

        // 56 cards in a deck.
        uint cardIndex = roll[0] % 56;

        cards.push(cardIndex);

        return cardIndex;
    }

    // Retrieve pet details by owner. This index is relative to the owner;
    // it is not the token index.
    function cardDetails(
        address _owner,
        uint _ownerIndex
    ) public view returns (uint[] memory) {
        return ChaosFarmContract.rollerResults(_owner, _ownerIndex);
    }

    // Checks if this account has a roll in progress. If not, the account
    // is able to add a pet.
    function readyForNewCard(address _roller) public view returns (bool) {
        return ChaosFarmContract.readyToRoll(_roller);
    }
}
