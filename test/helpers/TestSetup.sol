// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../../src/Chaos.sol";
import "../mocks/MockLinkToken.sol";
import "../mocks/MockVRFCoordinatorV2.sol";

abstract contract TestSetup is Test {
    Chaos internal chaos;

    LinkToken public linkToken;
    MockVRFCoordinatorV2 public vrfCoordinator;
    VRFConsumerV2 public vrfConsumer;

    // Fund the Chainlink subscription
    uint96 constant FUND_AMOUNT = 1 * 10**18;
    // Initialized as blank, fine for testing
    uint64 subscriptionId;
    // gasLane
    bytes32 keyHash;

    address payable[] internal users;
    address internal owner;
    address internal alice;

    // Used to build test user wallet addresses
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function setUp() public virtual {
        // Chainlink setup
        linkToken = new MockLinkToken();
        vrfCoordinator = new MockVRFCoordinatorV2();
        subscriptionId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subId, FUND_AMOUNT);
        vrfConsumer = new VRFConsumerV2(
            subscriptionId,
            address(vrfCoordinator),
            address(linkToken),
            keyHash
        );
        vrfCoordinator.addConsumer(subId, address(vrfConsumer));

        // Account setup
        users = createUsers(2);

        owner = users[0];
        vm.label(owner, "Owner");

        alice = users[1];
        vm.label(alice, "Alice");

        // 6 words per request
        uint32 numWords = 6;

        // Contract under test
        chaos = new Chaos(
            keyHash,
            subscriptionId,
            address(vrfCoordinator),
            numWords
        );
    }

    function getNextUserAddress() external returns (address payable) {
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    // create users with 100 ETH balance each
    function createUsers(uint256 userNum)
        internal
        returns (address payable[] memory)
    {
        address payable[] memory testUsers = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            address payable user = this.getNextUserAddress();
            vm.deal(user, 100 ether);
            testUsers[i] = user;
        }

        return testUsers;
    }
}
