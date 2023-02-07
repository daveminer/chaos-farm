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

// Chaos Farm provides the random values that determine the
// species of the pet.
contract PetExample {
    address payable public owner;
    ChaosFarmInterface ChaosFarmContract;

    string[] pets;
    mapping(address => uint[]) public handlers;

    constructor(address _petStoreAddress) {
        owner = payable(msg.sender);
        ChaosFarmContract = ChaosFarmInterface(_petStoreAddress);
    }

    function lastPet(address _owner) public view returns (uint[] memory) {
        return ChaosFarmContract.lastRoll(_owner);
    }

    // Create a random pet for the caller.
    function newPet() public returns (uint) {
        return ChaosFarmContract.rollDice(msg.sender);
    }

    // Retrieve pet details by owner. This index is relative to the owner;
    // it is not the token index.
    function petDetails(
        address _owner,
        uint _ownerIndex
    ) public view returns (uint[] memory) {
        return ChaosFarmContract.rollerResults(_owner, _ownerIndex);
    }
}
