// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/GrantRegistry.sol";

contract GrantRegistryTest is Test {
    GrantRegistry registry;

    address creator = address(1);
    address user = address(2);

    function setUp() public {
        registry = new GrantRegistry();
    }

    function testCreateGrant() public {
        vm.prank(creator);
        uint256 grantId = registry.createGrant(
            "ipfs://metadata",
            block.timestamp + 7 days
        );

        (
            address storedCreator,
            ,
            uint256 deadline,
            GrantRegistry.GrantStatus status
        ) = registry.grants(grantId);

        assertEq(storedCreator, creator);
        assertEq(deadline, block.timestamp + 7 days);
        assertEq(uint256(status), uint256(GrantRegistry.GrantStatus.Created));
    }

    function testOnlyCreatorCanMoveToFunding() public {
        vm.prank(creator);
        uint256 grantId = registry.createGrant(
            "ipfs://data",
            block.timestamp + 7 days
        );

        vm.expectRevert();
        vm.prank(user);
        registry.moveToFunding(grantId);
    }

    function testMoveToReviewAfterDeadline() public {
        vm.prank(creator);
        uint256 grantId = registry.createGrant(
            "ipfs://data",
            block.timestamp + 3 days
        );

        vm.prank(creator);
        registry.moveToFunding(grantId);

        vm.warp(block.timestamp + 4 days);
        registry.moveToReview(grantId);

        (, , , GrantRegistry.GrantStatus status) = registry.grants(grantId);
        assertEq(uint256(status), uint256(GrantRegistry.GrantStatus.Review));
    }
}
