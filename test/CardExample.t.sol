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

    function testRequestNewCard() public {
        createCardWithCallback(alice);

        vm.prank(alice);
        cardExample.requestNewCard();
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

    function testCardDescription() public {
        createCardWithCallback(alice);

        string memory description = cardExample.cardDescription(0);

        assertEq(description, "1 of Diamonds");
    }

    function testSuit() public {
        createCardWithCallback(alice);

        string memory suit = cardExample.suit(0);

        assertEq(suit, "Diamonds");
    }

    function testCardValue() public {
        createCardWithCallback(alice);

        string memory value = cardExample.cardValue(0);

        assertEq(value, "1");
    }

    function createCardWithCallback(address requester) private {
        vm.prank(requester);
        uint request = cardExample.requestNewCard();

        vrfCoordinator.fulfillRandomWords(request, address(chaos));

        vm.prank(requester);
        cardExample.completeNewCard();
    }
}
