// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/GrantRegistry.sol";
import "../../../src/FundingVault.sol";

contract FundingInvariantTest is Test {
    GrantRegistry registry;
    FundingVault vault;

    address creator = address(1);
    address alice = address(2);
    address bob = address(3);

    uint256 grantId;

    function setUp() public {
        registry = new GrantRegistry();
        vault = new FundingVault(address(registry));

        deal(alice, 10 ether);
        deal(bob, 10 ether);

        vm.prank(creator);
        grantId = registry.createGrant(
            "ipfs://grant",
            block.timestamp + 10 days
        );

        vm.prank(creator);
        registry.moveToFunding(grantId);
    }

    function invariant_VaultBalanceEqualsTotalFunds() public {
        assertEq(
            address(vault).balance,
            vault.totalFunds(grantId),
            "Vault balance mismatch"
        );
    }

    function testMultipleFundingInvariant() public {
        vm.prank(alice);
        vault.fundGrant{value: 3 ether}(grantId);

        vm.prank(bob);
        vault.fundGrant{value: 2 ether}(grantId);

        invariant_VaultBalanceEqualsTotalFunds();
    }
}
