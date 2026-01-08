// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/GrantRegistry.sol";
import "../../../src/FundingVault.sol";
import "./ReentrancyAttacker.sol";

contract ReentrancyAttackTest  is Test {
    GrantRegistry registry;
    FundingVault vault;
    ReentrancyAttacker attacker;

    address creator = address(1);

    function setUp() public {
        registry = new GrantRegistry();
        vault = new FundingVault(address(registry));

        vm.prank(creator);
        uint256 grantId = registry.createGrant(
            "ipfs://attack",
            block.timestamp + 1 days
        );

        vm.prank(creator);
        registry.moveToFunding(grantId);

        vm.warp(block.timestamp + 2 days);
        registry.moveToReview(grantId);
        registry.finalizeGrant(grantId, false);

        attacker = new ReentrancyAttacker(address(vault), grantId);
        deal(address(attacker), 1 ether);
    }

    function testReentrancyFails() public {
        vm.expectRevert();
        attacker.attack{value: 1 ether}();
    }
}
