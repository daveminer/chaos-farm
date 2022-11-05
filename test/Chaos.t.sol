// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "./helpers/TestSetup.sol";
import "../src/Chaos.sol";

contract ChaosTest is TestSetup {
    event RollStarted(uint256 indexed requestId, address indexed roller);
    event RollFinished(uint256 indexed requestId, uint256[] indexed result);

    function setUp() public override {
        super.setUp();
    }

    function testRollDiceSuccess() public {
        // Roll random numbers for users
        uint[] memory requestIds = new uint[](5);

        requestIds[0] = rollForAddress(address(bob));
        requestIds[1] = rollForAddress(address(bob));
        requestIds[2] = rollForAddress(address(carol));
        requestIds[3] = rollForAddress(address(bob));
        requestIds[4] = rollForAddress(address(carol));
    }

    function testLastRollInitial() public {
        uint[] memory roll = chaos.lastRoll(address(bob));
        assert(roll.length == 0);
    }

    function testLastRollInProgress() public {
        vm.expectEmit(true, true, false, false);
        emit RollStarted(1, address(bob));

        rollForAddress(address(bob));

        uint[] memory roll = chaos.lastRoll(address(bob));

        uint32 wordSize = chaos.numWords();
        uint rollLength = uint(wordSize);

        assert(roll.length == rollLength);
        for (uint i = 0; i < rollLength; i++) {
            assert(roll[i] == 0);
        }
    }

    function testLastRollReady() public {
        vm.expectEmit(true, true, false, false);
        emit RollStarted(1, address(bob));

        uint rollInProgress = rollForAddress(address(bob));

        uint[] memory roll = chaos.lastRoll(address(bob));
        for (uint i = 0; i < roll.length; i++) {
            assert(roll[i] == 0);
        }

        vm.expectEmit(true, false, false, false);
        emit RollFinished(1, new uint[](chaos.numWords()));

        vrfCoordinator.fulfillRandomWords(rollInProgress, address(chaos));

        uint[] memory finishedRoll = chaos.lastRoll(address(bob));
        for (uint i = 0; i < finishedRoll.length; i++) {
            assert(finishedRoll[i] != 0);
        }
    }

    function rollForAddress(address _roller) private returns (uint requestId) {
        vm.prank(chaos.allowedCaller());
        return chaos.rollDice(_roller);
    }
}
