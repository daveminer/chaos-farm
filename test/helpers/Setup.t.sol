// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract TestSetup is Test {
    Utils internal utils;
    Chaos internal chaos;

    address internal owner;
    address internal alice;

    function setUp() public virtual {
        utils = new Utils();
        users = utils.createUsers(1);

        owner = users[0];
        vm.label(owner, "Owner");

        alice = users[1];
        vm.label(dev, "Alice");

        chaos = new Chaos();
    }
}
