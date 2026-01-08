// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/GrantRegistry.sol";
import "../../../src/FundingVault.sol";

contract FundingVaultTest is Test {
    GrantRegistry registry;
    FundingVault vault;

    address creator = address(1);
    address alice = address(2);
    address bob = address(3);

    function setUp() public {
        registry = new GrantRegistry();
        vault = new FundingVault(address(registry));

        deal(alice, 10 ether);
        deal(bob, 10 ether);
    }

    function _createAndFundGrant() internal returns (uint256) {
        vm.prank(creator);
        uint256 grantId = registry.createGrant(
            "ipfs://grant",
            block.timestamp + 5 days
        );

        vm.prank(creator);
        registry.moveToFunding(grantId);

        vm.prank(alice);
        vault.fundGrant{value: 2 ether}(grantId);

        vm.prank(bob);
        vault.fundGrant{value: 3 ether}(grantId);

        return grantId;
    }

    function testFundingIncreasesBalance() public {
        uint256 grantId = _createAndFundGrant();

        assertEq(vault.totalFunds(grantId), 5 ether);
        assertEq(address(vault).balance, 5 ether);
    }

    function testCreatorWithdrawAfterApproval() public {
        uint256 grantId = _createAndFundGrant();

        vm.warp(block.timestamp + 6 days);
        registry.moveToReview(grantId);
        registry.finalizeGrant(grantId, true);

        uint256 before = creator.balance;

        vm.prank(creator);
        vault.withdraw(grantId);

        assertEq(creator.balance, before + 5 ether);
        assertEq(vault.totalFunds(grantId), 0);
    }

    function testRefundAfterRejection() public {
        uint256 grantId = _createAndFundGrant();

        vm.warp(block.timestamp + 6 days);
        registry.moveToReview(grantId);
        registry.finalizeGrant(grantId, false);

        uint256 before = alice.balance;

        vm.prank(alice);
        vault.refund(grantId);

        assertEq(alice.balance, before + 2 ether);
    }

    function testCannotWithdrawIfNotApproved() public {
        uint256 grantId = _createAndFundGrant();

        vm.expectRevert();
        vm.prank(creator);
        vault.withdraw(grantId);
    }
}
