// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Marketplace} from "../src/Marketplace.sol";
import "../src/ERC721Mock.sol";
import "./Helpers.sol";

contract MarketPlaceTest is Helpers {
    Marketplace mPlace;
    OurNFT nft;

    uint256 currentListingId;

    address userA;
    address userB;

    uint256 privKeyA;
    uint256 privKeyB;

    Marketplace.Listing l;

    function setUp() public {
        mPlace = new Marketplace();
        nft = new OurNFT();

        (userA, privKeyA) = mkaddr("USERA");
        (userB, privKeyB) = mkaddr("USERB");

        l = Marketplace.Listing({
            token: address(nft),
            tokenId: 1,
            price: 1 ether,
            sig: bytes(""),
            deadline: 0,
            lister: address(0),
            active: false
        });

        // mint NFT
        nft.mint(userA, 1);
    }

    function testOwnerCannotCreateListing() public {
        l.lister = userB;
        switchSigner(userB);

        vm.expectRevert(Marketplace.NotOwner.selector);
        mPlace.createListing(l);
    }

    function testNonApprovedNFT() public {
        switchSigner(userA);
        vm.expectRevert(Marketplace.NotApproved.selector);
        mPlace.createListing(l);
    }

    /*function testNonAddressZero() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        l.token = address(0);
        vm.expectRevert(Marketplace.AddressZero.selector);
        mPlace.createListing(l);
    }*/

    function testMinPriceTooLow() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        l.price = 0;
        vm.expectRevert(Marketplace.MinPriceTooLow.selector);
        mPlace.createListing(l);
    }

    function testMinDeadline() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        vm.expectRevert(Marketplace.DeadlineTooSoon.selector);
        mPlace.createListing(l);
    }

    function testMinDuration() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        l.deadline = uint88(block.timestamp + 59 minutes);
        vm.expectRevert(Marketplace.MinDurationNotMet.selector);
        mPlace.createListing(l);
    }

    function testValidSig() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        l.deadline = uint88(block.timestamp + 120 minutes);
        l.sig = constructSig(
            l.token,
            l.tokenId,
            l.price,
            l.deadline,
            l.lister,
            privKeyB
        );
        vm.expectRevert(Marketplace.InvalidSignature.selector);
        mPlace.createListing(l);
    }

    // EDIT LISTING
    function testEditNonValidListing() public {
        switchSigner(userA);
        vm.expectRevert(Marketplace.ListingNotExistent.selector);
        mPlace.editListing(1, 0, false);
    }

    function testEditListingNotOwner() public {
        switchSigner(userA);
        l.deadline = uint88(block.timestamp + 120 minutes);
        l.sig = constructSig(
            l.token,
            l.tokenId,
            l.price,
            l.deadline,
            l.lister,
            privKeyA
        );
        vm.expectRevert(Marketplace.ListingNotExistent.selector);
        uint256 lId = mPlace.createListing(l);

        switchSigner(userB);
        vm.expectRevert(Marketplace.NotOwner.selector);
        mPlace.editListing(lId, 0, false);
    }

    function testEditListing() public {
        switchSigner(userA);
        l.deadline = uint88(block.timestamp + 120 minutes);
        l.sig = constructSig(
            l.token,
            l.tokenId,
            l.price,
            l.deadline,
            l.lister,
            privKeyA
        );
        uint256 lId = mPlace.createListing(l);
        mPlace.editListing(lId, 0.01 ether, false);

        Marketplace.Listing memory t = mPlace.getListing(lId);
        assertEq(t.price, 0.01 ether);
        assertEq(t.active, false);
    }

    // EXECUTE LISTING
    function testExecuteNonValidListing() public {
        switchSigner(userA);
        vm.expectRevert(Marketplace.ListingNotExistent.selector);
        mPlace.executeListing(1);
    }

    function testExecuteExpiredListing() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
    }

    function testExecuteListingNotActive() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        l.deadline = uint88(block.timestamp + 120 minutes);
        l.sig = constructSig(
            l.token,
            l.tokenId,
            l.price,
            l.deadline,
            l.lister,
            privKeyA
        );
        uint256 lId = mPlace.createListing(l);
        switchSigner(userB);
        vm.expectRevert(Marketplace.ListingNotActive.selector);
        mPlace.executeListing(lId);
    }

    function testExecutePriceNotMet() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        l.deadline = uint88(block.timestamp + 120 minutes);
        l.sig = constructSig(
            l.token,
            l.tokenId,
            l.price,
            l.deadline,
            l.lister,
            privKeyA
        );
        uint256 lId = mPlace.createListing(l);
        switchSigner(userB);
        vm.expectRevert(
            abi.encodeWithSelector(
                Marketplace.PriceNotMet.selector,
                l.price - 0.9 ether
            )
        );
        mPlace.executeListing{value: 0.9 ether}(lId);
    }

    /*function testExecutePriceNotMet() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        l.deadline = uint88(block.timestamp + 120 minutes);
        l.sig = constructSig(
            l.token,
            l.tokenId,
            l.price,
            l.deadline,
            l.lister,
            privKeyA
        );
        uint256 lId = mPlace.createListing(l);
        switchSigner(userB);
        vm.expectRevert(
            abi.encodeWithSelector(
                Marketplace.PriceNotMet.selector,
                l.price - 0.9 ether
            )
        );
        mPlace.executeListing{value: 1.1 ether}(lId);
    }*/

    function testExecute() public {
        switchSigner(userA);
        nft.setApprovalForAll(address(mPlace), true);
        l.deadline = uint88(block.timestamp + 120 minutes);
        l.sig = constructSig(
            l.token,
            l.tokenId,
            l.price,
            l.deadline,
            l.lister,
            privKeyA
        );
        uint256 lId = mPlace.createListing(l);
        switchSigner(userB);
        uint256 userABalanceBefore = userA.balance;

        mPlace.executeListing{value: l.price}(lId);

        Marketplace.Listing memory t = mPlace.getListing(lId);
        assertEq(t.price, 0.01 ether);
        assertEq(t.active, false);

        vm.expectRevert(
            abi.encodeWithSelector(
                Marketplace.PriceNotMet.selector,
                l.price - 0.9 ether
            )
        );
        assertEq(t.active, false);
        assertEq(ERC721(l.token).ownerOf(l.tokenId), userB);
    }
}
