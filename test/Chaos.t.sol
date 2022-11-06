// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "./helpers/TestSetup.sol";
import "../src/Chaos.sol";

contract ChaosTest is TestSetup {
    uint[] requestIds;

    event AllowedAddressChanged(
        address indexed oldAddress,
        address indexed newAddress
    );
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

        vm.prank(address(chaos.owner()));
        vm.expectEmit(true, true, false, false);
        emit AllowedAddressChanged(alice, bob);
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
        chaos.rollDice(address(alice));

        // Never rolled before
        vm.expectEmit(true, false, false, false);
        emit RollStarted(6, address(0));
        rollForAddress(address(alice));

        // Last roll is complete
        vm.expectEmit(true, false, false, false);
        emit RollStarted(7, address(0));
        rollForAddress(address(bob));

        // Last roll in progress
        vm.prank(chaos.allowedCaller());
        vm.expectRevert(bytes("Roll in progress."));
        chaos.rollDice(address(carol));
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

    function testIntegration() public {
        // Alice is ready to roll; has no previous rolls.
        vm.expectRevert();
        chaos.s_results(address(alice), 0, 0);

        // Alice starts a roll for herself.
        requestIds.push(rollForAddress(address(alice)));

        // Check state
        assert(requestIds.length == 6);
        uint aliceRollOneValueOne = chaos.s_results(address(alice), 0, 0);
        assert(aliceRollOneValueOne == 0);

        // Carol tries to roll but roll in progress
        vm.prank(chaos.allowedCaller());
        vm.expectRevert(bytes("Roll in progress."));
        chaos.rollDice(address(carol));

        // Check state
        assert(requestIds.length == 6);

        // Bob checks and is ready
        bool bobReady = chaos.readyToRoll(address(bob));
        assert(bobReady == true);

        // Bob is ready and starts a roll
        requestIds.push(rollForAddress(address(bob)));

        // Roll checks
        assert(requestIds.length == 7);

        // Bob checks, not ready
        bool bobStillReady = chaos.readyToRoll(address(bob));
        assert(bobStillReady == false);

        // Carol check status - not ready to roll
        bool carolReady = chaos.readyToRoll(address(carol));
        assert(carolReady == false);

        // Carol's roll finished
        vrfCoordinator.fulfillRandomWords(requestIds[4], address(chaos));

        // Roll checks
        assert(requestIds.length == 7);
        uint carolRollOneValueOne = chaos.s_results(address(carol), 0, 0);
        assert(carolRollOneValueOne > 0);

        // Bob's roll finishes
        vrfCoordinator.fulfillRandomWords(requestIds[6], address(chaos));

        // Check state
        assert(requestIds.length == 7);
        uint bobRollOneValueOne = chaos.s_results(address(bob), 3, 0);
        assert(bobRollOneValueOne > 0);

        // Alice's roll finishes
        vrfCoordinator.fulfillRandomWords(requestIds[5], address(chaos));

        // Check state
        assert(requestIds.length == 7);
        uint aliceRollOneFinishedValueOne = chaos.s_results(
            address(alice),
            0,
            0
        );
        assert(aliceRollOneFinishedValueOne > 0);

        // Alice rolls again
        requestIds.push(rollForAddress(address(alice)));

        // Check state
        assert(requestIds.length == 8);
        uint aliceRollTwoValueOne = chaos.s_results(address(alice), 1, 0);
        assert(aliceRollTwoValueOne == 0);

        // Alice finishes again
        vrfCoordinator.fulfillRandomWords(requestIds[7], address(chaos));

        // Check state
        assert(requestIds.length == 8);
        uint aliceRollTwoFinishedValueOne = chaos.s_results(
            address(alice),
            1,
            0
        );
        assert(aliceRollTwoFinishedValueOne > 0);
    }

    function rollForAddress(address _roller) private returns (uint requestId) {
        vm.prank(chaos.allowedCaller());
        return chaos.rollDice(_roller);
    }
}
