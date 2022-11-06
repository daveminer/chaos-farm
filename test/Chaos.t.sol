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

        // Roll random numbers for users
        uint[] memory requestIds = new uint[](5);

        requestIds[0] = rollForAddress(address(bob));
        vrfCoordinator.fulfillRandomWords(requestIds[0], address(chaos));
        requestIds[1] = rollForAddress(address(bob));
        vrfCoordinator.fulfillRandomWords(requestIds[1], address(chaos));

        requestIds[2] = rollForAddress(address(carol));
        vrfCoordinator.fulfillRandomWords(requestIds[2], address(chaos));

        requestIds[3] = rollForAddress(address(bob));
        vrfCoordinator.fulfillRandomWords(requestIds[3], address(chaos));

        // Carol's last roll is in progress.
        requestIds[4] = rollForAddress(address(carol));
    }

    function testLastRoll() public {
        // Never rolled before
        uint[] memory aliceLastRoll = chaos.lastRoll(address(alice));
        assert(aliceLastRoll.length == 0);

        // Last roll completed
        uint[] memory bobLastRoll = chaos.lastRoll(address(bob));
        assert(bobLastRoll.length == chaos.numWords());

        // Last roll in progress
        uint[] memory carolLastRoll = chaos.lastRoll(address(carol));
        assert(carolLastRoll.length == chaos.numWords());

        // Address has never rolled before, last roll is an empty array.
        // uint[] memory roll = chaos.lastRoll(address(alice));
        // assert(roll.length == 0);

        //vm.expectEmit(true, true, false, false);
        //emit RollStarted(1, address(bob));

        // uint rollInProgress = rollForAddress(address(bob));

        // // Roll is in progress; array is populated with 0s
        // roll = chaos.lastRoll(address(bob));
        // for (uint i = 0; i < roll.length; i++) {
        //     assert(roll[i] == 0);
        // }

        // vm.expectEmit(true, false, false, false);
        // emit RollFinished(1, new uint[](chaos.numWords()));

        // vrfCoordinator.fulfillRandomWords(rollInProgress, address(chaos));

        // // Roll complete. Random values are present in the array
        // uint[] memory finishedRoll = chaos.lastRoll(address(bob));
        // for (uint i = 0; i < finishedRoll.length; i++) {
        //     assert(finishedRoll[i] != 0);
        // }
    }

    function testReadyToRoll() public {
        // Never rolled before
        bool aliceReady = chaos.readyToRoll(address(alice));
        assert(aliceReady == true);

        // Last roll is complete
        bool bobReady = chaos.readyToRoll(address(bob));
        assert(bobReady == true);

        // Last roll in progress
        uint[] memory roll = chaos.lastRoll(address(carol));
        console.log(roll.length);
        bool carolReady = chaos.readyToRoll(address(carol));
        assert(carolReady == false);

        // uint[] memory firstRoll = chaos.lastRoll(address(bob));
        // for (uint i = 0; i < firstRoll.length; i++) {
        //     console.log(firstRoll[i], "F");
        // }

        // uint rollInProgress = rollForAddress(address(bob));

        // uint[] memory lastRoll = chaos.lastRoll(address(bob));
        // for (uint i = 0; i < lastRoll.length; i++) {
        //     console.log(lastRoll[i], "N");
        // }

        // bobReady = chaos.readyToRoll(address(bob));
        // console.log(bobReady, "BOBRDY");
        // //assert(bobReady == false);

        // vrfCoordinator.fulfillRandomWords(rollInProgress, address(chaos));

        // bobReady = chaos.readyToRoll(address(bob));
        // //assert(bobReady == true);
    }

    function testRollDice() public {
        // Never rolled before
        uint _aliceRequestId = rollForAddress(address(alice));

        // Last roll is complete
        uint _bobRequestId = rollForAddress(address(bob));

        // Last roll in progress
        vm.prank(chaos.allowedCaller());
        vm.expectRevert(bytes("Roll in progress."));
        uint carolRequestId = chaos.rollDice(address(carol));
    }

    function rollForAddress(address _roller) private returns (uint requestId) {
        vm.prank(chaos.allowedCaller());
        return chaos.rollDice(_roller);
    }
}
