// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ChaosFarmInterface {
    function lastRoll(address _roller) external view returns (uint[] memory);

    function readyToRoll(address _roller) external view returns (bool);

    function rollDice(address _roller) external returns (uint);

    function rollerResults(
        address _roller,
        uint _rollIndex
    ) external view returns (uint[] memory);

    function setAllowedCaller(address _allowedCaller) external;
}

// Chaos Farm provides the random values that are used to create
// a playing card. The card state exists independently from the
// random values in the VRF contract, though it references the
// VRF values for auditing / logging purposes. Note this requires
// overriding the callback to capture the roll state.
contract CardExample {
    address payable public owner;
    ChaosFarmInterface ChaosFarmContract;

    uint[] public cards;
    mapping(address => uint[]) public holders;

    constructor(address _deckAddress) {
        owner = payable(msg.sender);
        ChaosFarmContract = ChaosFarmInterface(_deckAddress);
    }

    function lastCard(address _owner) public view returns (uint[] memory) {
        return ChaosFarmContract.lastRoll(_owner);
    }

    // Create a random card for the caller.
    function requestNewCard() public returns (uint) {
        return ChaosFarmContract.rollDice(msg.sender);
    }

    function completeNewCard() public returns (uint) {
        uint[] memory roll = ChaosFarmContract.lastRoll(msg.sender);

        holders[msg.sender].push(cards.length);

        // 56 cards in a deck. Only the first value is used.
        uint cardIndex = roll[0] % 56;

        cards.push(cardIndex);

        return cardIndex;
    }

    // Checks if this account has a roll in progress. If not, the account
    // is able to add a card.
    function readyForNewCard(address _roller) public view returns (bool) {
        return ChaosFarmContract.readyToRoll(_roller);
    }

    // Retrieve card details by owner. This index is relative to the owner;
    // it is not the token index.
    function cardDetails(
        address _owner,
        uint _ownerIndex
    ) public view returns (uint[] memory) {
        return ChaosFarmContract.rollerResults(_owner, _ownerIndex);
    }

    // Returns the readable string description of the card
    function cardDescription(uint _cardIndex) public view returns (string memory) {
        string memory suitDesc = suit(_cardIndex);
        string memory value = cardValue(_cardIndex);

        string memory description = string(abi.encodePacked(value, " of ", suitDesc));

        return description;
    }

    function suit(uint _cardIndex) public view returns (string memory) {
        uint card = cards[_cardIndex];

        uint suitNumber = card / 4;

        string memory suitStr;

        if (suitNumber == 0) {
            suitStr = "Clubs";
        } else if (suitNumber == 1) {
            suitStr = "Spades";
        } else if (suitNumber == 2) {
            suitStr = "Hearts";
        } else {
            suitStr = "Diamonds";
        }

        return suitStr;
    }

    function cardValue(uint _cardIndex) public view returns (string memory) {
        uint card = cards[_cardIndex];

        uint valueNumber = card % 4;

        string memory value;

        if (valueNumber < 11) {
            value = uintToStr(valueNumber);
        } else if (valueNumber == 11) {
            value = "Jack";
        } else if (valueNumber == 12) {
            value = "Queen";
        } else if (valueNumber == 13) {
            value = "King";
        } else {
            value = "Ace";
        }

        return value;
    }

    function uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
