// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/Chaos.sol";

contract ChaosTest is TestSetup {
    Chaos public chaos;

    address internal alice;

    function setUp() public {
        chaos = new Chaos();
    }
    // Counter public counter;

    // function setUp() public {
    //     counter = new Counter();
    //     counter.setNumber(0);
    // }

    // function testIncrement() public {
    //     counter.increment();
    //     assertEq(counter.number(), 1);
    // }

    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
