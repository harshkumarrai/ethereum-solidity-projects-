// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/GrantRegistry.sol";
import "../../../src/Governance.sol";

contract GovernanceTest is Test {
    GrantRegistry registry;
    Governance governance;

    address voter1 = address(1);
    address voter2 = address(2);

    function setUp() public {
        registry = new GrantRegistry();
        governance = new Governance(address(registry));
    }

    function testGovernanceVoteApprovesGrant() public {
        vm.prank(voter1);
        uint256 grantId = registry.createGrant(
            "ipfs://grant",
            block.timestamp + 3 days
        );

        vm.prank(voter1);
        registry.moveToFunding(grantId);

        vm.warp(block.timestamp + 4 days);
        registry.moveToReview(grantId);

        governance.createVote(grantId);

        vm.prank(voter1);
        governance.vote(grantId, true);

        vm.prank(voter2);
        governance.vote(grantId, false);

        vm.prank(voter1);
        governance.vote(grantId, true);

        vm.warp(block.timestamp + 4 days);
        governance.execute(grantId);

        (, , , GrantRegistry.GrantStatus status) = registry.grants(grantId);
        assertEq(uint256(status), uint256(GrantRegistry.GrantStatus.Approved));
    }
}
