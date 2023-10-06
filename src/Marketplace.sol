// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import {SignUtils} from "./libraries/SignUtils.sol";

contract Marketplace {
    struct Order {
        address token;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        // Slot 4
        uint88 deadline;
        address owner;
        bool active;
    }

    mapping(uint256 => Order) public orders;
    address public admin;
    uint256 public orderId;

    /* ERRORS */
    error NotOwner();
    error NotApproved();
    error MinPriceTooLow();
    error DeadlineTooSoon();
    error MinDurationNotMet();
    error InvalidSignature();
    error OrderNotExistent();
    error OrderNotActive();
    error PriceNotMet(int256 difference);
    error OrderExpired();
    error PriceMismatch(uint256 originalPrice);

    /* EVENTS */
    event OrderCreated(uint256 indexed orderId, Order);
    event OrderExecuted(uint256 indexed orderId, Order);
    event OrderEdited(uint256 indexed orderId, Order);

    constructor() {}

    function createOrder(Order calldata l) public returns (uint256 lId) {
        if (ERC721(l.token).ownerOf(l.tokenId) != msg.sender) revert NotOwner();
        if (!ERC721(l.token).isApprovedForAll(msg.sender, address(this)))
            revert NotApproved();
        if (l.price < 0.01 ether) revert MinPriceTooLow();
        if (l.deadline < block.timestamp) revert DeadlineTooSoon();
        if (l.deadline - block.timestamp < 60 minutes)
            revert MinDurationNotMet();

        // Assert signature
        if (
            !SignUtils.isValid(
                SignUtils.constructMessageHash(
                    l.token,
                    l.tokenId,
                    l.price,
                    l.deadline,
                    l.owner
                ),
                l.signature,
                msg.sender
            )
        ) revert InvalidSignature();

        // append to Storage
        Order storage li = orders[orderId];
        li.token = l.token;
        li.tokenId = l.tokenId;
        li.price = l.price;
        li.signature = l.signature;
        li.deadline = uint88(l.deadline);
        li.owner = msg.sender;
        li.active = true;

        // Emit event
        emit OrderCreated(orderId, l);
        lId = orderId;
        orderId++;
        return lId;
    }

    function executeOrder(uint256 _orderId) public payable {
        if (_orderId >= orderId) revert OrderNotExistent();
        Order storage order = orders[_orderId];
        if (order.deadline < block.timestamp) revert OrderExpired();
        if (!order.active) revert OrderNotActive();
        if (order.price < msg.value) revert PriceMismatch(order.price);
        if (order.price != msg.value)
            revert PriceNotMet(int256(order.price) - int256(msg.value));

        // Update state
        order.active = false;

        // transfer
        ERC721(order.token).transferFrom(
            order.owner,
            msg.sender,
            order.tokenId
        );

        // transfer eth
        payable(order.owner).transfer(order.price);

        // Update storage
        emit OrderExecuted(_orderId, order);
    }

    function editOrder(
        uint256 _orderId,
        uint256 _newPrice,
        bool _active
    ) public {
        if (_orderId >= orderId) revert OrderNotExistent();
        Order storage order = orders[_orderId];
        if (order.owner != msg.sender) revert NotOwner();
        order.price = _newPrice;
        order.active = _active;
        emit OrderEdited(_orderId, order);
    }

    // add getter for order
    function getOrder(uint256 _orderId) public view returns (Order memory) {
        // if (_orderId >= orderId)
        return orders[_orderId];
    }
}
