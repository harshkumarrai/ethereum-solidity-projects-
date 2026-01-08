// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/GrantRegistry.sol";
import "../../../src/FundingVault.sol";

contract FundingFuzzTest is Test {
    GrantRegistry registry;
    FundingVault vault;

    address user = address(1);
    address creator = address(2);
    uint256 grantId;

    function setUp() public {
        registry = new GrantRegistry();
        vault = new FundingVault(address(registry));

        deal(user, 100 ether);

        vm.prank(creator);
        grantId = registry.createGrant(
            "ipfs://fuzz",
            block.timestamp + 5 days
        );

        vm.prank(creator);
        registry.moveToFunding(grantId);
    }

    function testFuzzFunding(uint96 amount) public {
        vm.assume(amount > 1e9); // > 1 gwei
        vm.assume(amount < 50 ether);

        vm.prank(user);
        vault.fundGrant{value: amount}(grantId);

        assertEq(vault.totalFunds(grantId), amount);
        assertEq(vault.contributions(grantId, user), amount);
    }
}
