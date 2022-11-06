// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "./helpers/TestSetup.sol";
import "../src/Chaos.sol";

contract ChaosTest is TestSetup {
    uint[] requestIds;

    event RollStarted(uint256 indexed requestId, address indexed roller);
    event RollFinished(uint256 indexed requestId, uint256[] indexed result);

    function setUp() public override {
        super.setUp();

        requestIds.push(rollForAddress(address(bob)));
        vrfCoordinator.fulfillRandomWords(requestIds[0], address(chaos));
        requestIds.push(rollForAddress(address(bob)));
        vrfCoordinator.fulfillRandomWords(requestIds[1], address(chaos));

        requestIds.push(rollForAddress(address(carol)));
        vrfCoordinator.fulfillRandomWords(requestIds[2], address(chaos));

        requestIds.push(rollForAddress(address(bob)));
        vrfCoordinator.fulfillRandomWords(requestIds[3], address(chaos));

        // Carol's last roll is in progress.
        requestIds.push(rollForAddress(address(carol)));
    }

    function testSetAllowedCaller() public {
        // Access control
        vm.prank(address(bob));
        vm.expectRevert(bytes("Must be owner."));
        chaos.setAllowedCaller(address(bob));
    }

    function testLastRoll() public view {
        // Never rolled before
        uint[] memory aliceLastRoll = chaos.lastRoll(address(alice));
        assert(aliceLastRoll.length == 0);

        // Last roll completed
        uint[] memory bobLastRoll = chaos.lastRoll(address(bob));
        assert(bobLastRoll.length == chaos.numWords());

        // Last roll in progress
        uint[] memory carolLastRoll = chaos.lastRoll(address(carol));
        assert(carolLastRoll.length == chaos.numWords());
    }

    function testReadyToRoll() public view {
        // Never rolled before
        bool aliceReady = chaos.readyToRoll(address(alice));
        assert(aliceReady == true);

        // Last roll is complete
        bool bobReady = chaos.readyToRoll(address(bob));
        assert(bobReady == true);

        // Last roll in progress
        bool carolReady = chaos.readyToRoll(address(carol));
        assert(carolReady == false);
    }

    function testRollDice() public {
        // Only allowed address can call
        vm.prank(address(bob));
        vm.expectRevert(bytes("Must be allowed caller."));
        uint failedRequestId = chaos.rollDice(address(alice));

        // Never rolled before
        uint _aliceRequestId = rollForAddress(address(alice));

        // Last roll is complete
        uint _bobRequestId = rollForAddress(address(bob));

        // Last roll in progress
        vm.prank(chaos.allowedCaller());
        vm.expectRevert(bytes("Roll in progress."));
        uint carolRequestId = chaos.rollDice(address(carol));
    }

    function testFulfillRandomWords() public {
        vm.expectEmit(true, false, false, false);
        emit RollFinished(5, new uint[](chaos.numWords()));

        uint[] memory roll = chaos.lastRoll(address(carol));
        for (uint i = 0; i < roll.length; i++) {
            assert(roll[i] == 0);
        }

        // Carol's last roll is in progress
        vrfCoordinator.fulfillRandomWords(requestIds[4], address(chaos));

        uint[] memory finishedRoll = chaos.lastRoll(address(carol));
        for (uint i = 0; i < finishedRoll.length; i++) {
            assert(finishedRoll[i] != 0);
        }
    }

    //function testIntegration() public {}

    function rollForAddress(address _roller) private returns (uint requestId) {
        vm.prank(chaos.allowedCaller());
        return chaos.rollDice(_roller);
    }
}
