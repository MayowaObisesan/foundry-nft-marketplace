// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Marketplace} from "../src/Marketplace.sol";
import "../src/ERC721Mock.sol";
import "./Helpers.sol";

contract MarketPlaceTest is Helpers {
    Marketplace mPlace;
    OurNFT nft;

    uint256 currentOrderId;

    address userA;
    address userB;

    uint256 privKeyA;
    uint256 privKeyB;

    Marketplace.Order order;

    function setUp() public {
        mPlace = new Marketplace();
        nft = new OurNFT();

        (userA, privKeyA) = mkaddr("USERA");
        (userB, privKeyB) = mkaddr("USERB");

        order = Marketplace.Order({
            token: address(nft),
            tokenId: 1,
            price: 1 ether,
            signature: bytes(""),
            deadline: 0,
            owner: address(0),
            active: false
        });

        nft.mint(userA, 1);
    }

    function testOwnerCannotCreateOrder() public {
        order.owner = userB;
        switchSigner(userB);

        vm.expectRevert(Marketplace.NotOwner.selector);
        mPlace.createOrder(order);
    }

    function testNFTNotApproved() public {
        switchSigner(userA);
        vm.expectRevert(Marketplace.NotApproved.selector);
        mPlace.createOrder(order);
    }

    function testMinPriceTooLow() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        order.price = 0;
        vm.expectRevert(Marketplace.MinPriceTooLow.selector);
        mPlace.createOrder(order);
    }

    function testMinDeadline() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        vm.expectRevert(Marketplace.DeadlineTooSoon.selector);
        mPlace.createOrder(order);
    }

    function testMinDuration() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        order.deadline = uint88(block.timestamp + 59 minutes);
        vm.expectRevert(Marketplace.MinDurationNotMet.selector);
        mPlace.createOrder(order);
    }

    function testSignatureNotValid() public {
        // Test that signature is valid
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        order.deadline = uint88(block.timestamp + 120 minutes);
        order.signature = constructSig(
            order.token,
            order.tokenId,
            order.price,
            order.deadline,
            order.owner,
            privKeyB
        );
        vm.expectRevert(Marketplace.InvalidSignature.selector);
        mPlace.createOrder(order);
    }

    // EDIT Order
    function testEditNonValidOrder() public {
        switchSigner(userA);
        vm.expectRevert(Marketplace.OrderNotExistent.selector);
        mPlace.editOrder(1, 0, false);
    }

    function testEditOrderNotOwner() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        order.deadline = uint88(block.timestamp + 120 minutes);
        order.signature = constructSig(
            order.token,
            order.tokenId,
            order.price,
            order.deadline,
            order.owner,
            privKeyA
        );
        // vm.expectRevert(Marketplace.OrderNotExistent.selector);
        uint256 newOrderId = mPlace.createOrder(order);

        switchSigner(userB);
        vm.expectRevert(Marketplace.NotOwner.selector);
        mPlace.editOrder(newOrderId, 0, false);
    }

    function testEditOrder() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        order.deadline = uint88(block.timestamp + 120 minutes);
        order.signature = constructSig(
            order.token,
            order.tokenId,
            order.price,
            order.deadline,
            order.owner,
            privKeyA
        );
        uint256 newOrderId = mPlace.createOrder(order);
        mPlace.editOrder(newOrderId, 0.01 ether, false);

        Marketplace.Order memory _order = mPlace.getOrder(newOrderId);
        assertEq(_order.price, 0.01 ether);
        assertEq(_order.active, false);
    }

    // EXECUTE Order
    function testExecuteNonValidOrder() public {
        switchSigner(userA);
        vm.expectRevert(Marketplace.OrderNotExistent.selector);
        mPlace.executeOrder(1);
    }

    function testExecuteExpiredOrder() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
    }

    function testExecuteOrderNotActive() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        order.deadline = uint88(block.timestamp + 120 minutes);
        order.signature = constructSig(
            order.token,
            order.tokenId,
            order.price,
            order.deadline,
            order.owner,
            privKeyA
        );
        uint256 newOrderId = mPlace.createOrder(order);
        mPlace.editOrder(newOrderId, 0.01 ether, false);
        switchSigner(userB);
        vm.expectRevert(Marketplace.OrderNotActive.selector);
        mPlace.executeOrder(newOrderId);
    }

    function testFulfilOrderPriceNotEqual() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        order.deadline = uint88(block.timestamp + 120 minutes);
        order.signature = constructSig(
            order.token,
            order.tokenId,
            order.price,
            order.deadline,
            order.owner,
            privKeyA
        );
        uint256 newOrderId = mPlace.createOrder(order);
        switchSigner(userB);
        vm.expectRevert(
            abi.encodeWithSelector(
                Marketplace.PriceNotMet.selector,
                order.price - 0.9 ether
            )
        );
        mPlace.executeOrder{value: 0.9 ether}(newOrderId);
    }

    function testFulfilOrderPriceMismatch() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        order.deadline = uint88(block.timestamp + 120 minutes);
        order.signature = constructSig(
            order.token,
            order.tokenId,
            order.price,
            order.deadline,
            order.owner,
            privKeyA
        );
        uint256 newOrderId = mPlace.createOrder(order);
        switchSigner(userB);
        vm.expectRevert(
            abi.encodeWithSelector(
                Marketplace.PriceMismatch.selector,
                order.price
            )
        );
        mPlace.executeOrder{value: 1.1 ether}(newOrderId);
    }

    function testFulfilOrder() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        order.deadline = uint88(block.timestamp + 120 minutes);
        order.signature = constructSig(
            order.token,
            order.tokenId,
            order.price,
            order.deadline,
            order.owner,
            privKeyA
        );
        uint256 newOrderId = mPlace.createOrder(order);
        switchSigner(userB);
        uint256 userABalanceBefore = userA.balance;

        mPlace.executeOrder{value: order.price}(newOrderId);

        uint256 userABalanceAfter = userA.balance;

        Marketplace.Order memory _order = mPlace.getOrder(newOrderId);
        assertEq(_order.price, 1 ether);
        assertEq(_order.active, false);

        assertEq(_order.active, false);
        assertEq(ERC721(order.token).ownerOf(order.tokenId), userB);
        assertEq(userABalanceAfter, userABalanceBefore + order.price);
    }
}
