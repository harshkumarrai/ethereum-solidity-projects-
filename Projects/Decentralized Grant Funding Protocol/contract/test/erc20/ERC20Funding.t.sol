// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/GrantRegistry.sol";
import "./../../src/mocks/MockERC20.sol";
import "./../../src/extensions/ERC20FundingVault.sol";

contract ERC20FundingTest is Test {
    MockERC20 token;
    ERC20FundingVault vault;

    address user = address(1);

    function setUp() public {
        token = new MockERC20();
        vault = new ERC20FundingVault();

        token.transfer(user, 1000 ether);
    }

    function testERC20Funding() public {
        vm.startPrank(user);
        token.approve(address(vault), 500 ether);
        vault.fundERC20(1, address(token), 500 ether);
        vm.stopPrank();

        assertEq(vault.contributions(1, user), 500 ether);
    }
}
