// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "./helpers/TestSetup.sol";
import "../src/examples/CardExample.sol";

contract CardExampleTest is TestSetup {
    uint[] requestIds;
    CardExample cardExample;

    function setUp() public override {
        super.setUp();

        cardExample = new CardExample(address(chaos));

        chaos.setAllowedCaller(address(cardExample));
    }

    function testLastCard() public {
        createCardWithCallback(alice);

        uint[] memory details = cardExample.lastCard(address(alice));
        for (uint i = 0; i < details.length; i++) {
            assert(details[i] != 0);
        }
    }

    function testCardDetails() public {
        createCardWithCallback(alice);

        uint256[] memory details = cardExample.cardDetails(address(alice), 0);

        for (uint i = 0; i < details.length; i++) {
            assert(details[i] != 0);
        }
    }

    function createCardWithCallback(address requester) private {
        vm.prank(requester);
        uint request = cardExample.requestNewCard();

        vrfCoordinator.fulfillRandomWords(request, address(chaos));

        vm.prank(requester);
        cardExample.completeNewCard();
    }
}
