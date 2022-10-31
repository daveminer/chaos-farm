// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./helpers/TestSetup.sol";
import "../src/Chaos.sol";

contract ChaosTest is TestSetup {
    function setUp() public override {
        super.setUp();
    }

    // Counter public counter;

    // function setUp() public {
    //     counter = new Counter();
    //     counter.setNumber(0);
    // }

    function testAlwaysTrue() public {
        assertTrue(true);
    }

    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
