// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Marketplace {
    struct Listing {
        address token;
        uint256 tokenId;
        bytes sig;
        // Slot 4
        uint88 deadline;
        address lister;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
