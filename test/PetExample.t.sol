// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "./helpers/TestSetup.sol";
import "../src/examples/PetExample.sol";

contract PetExampleTest is TestSetup {
    uint[] requestIds;
    PetExample petExample;

    function setUp() public override {
        super.setUp();

        petExample = new PetExample(address(chaos));

        chaos.setAllowedCaller(address(petExample));
    }

    function testLastPet() public {
        vm.prank(address(alice));
        uint request = petExample.newPet();

        vrfCoordinator.fulfillRandomWords(request, address(chaos));

        uint[] memory details = petExample.lastPet(address(alice));
        for (uint i = 0; i < details.length; i++) {
            assert(details[i] != 0);
        }
    }

    function testNewPet() public {
        vm.prank(address(alice));
        petExample.newPet();

        uint[] memory lastPet = petExample.lastPet(address(alice));
        for (uint i = 0; i < lastPet.length; i++) {
            assert(lastPet[i] == 0);
        }
    }

    function testPetDetails() public {
        vm.prank(address(alice));
        uint request = petExample.newPet();

        vrfCoordinator.fulfillRandomWords(request, address(chaos));

        uint256[] memory details = petExample.petDetails(address(alice), 0);

        for (uint i = 0; i < details.length; i++) {
            assert(details[i] != 0);
        }
    }
}
