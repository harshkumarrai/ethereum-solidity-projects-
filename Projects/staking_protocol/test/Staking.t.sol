// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
    {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}


contract StakingTest is Test {
    Staking staking;
    MockERC20 stakeToken;
    MockERC20 rewardToken;

    address alice = address(0xA11CE);
    address bob   = address(0xB0B);
    address admin = address(this);

    uint256 constant REWARD_RATE = 10 ether; 
    function setUp() public {
        stakeToken = new MockERC20("StakeToken", "STK");
        rewardToken = new MockERC20("RewardToken", "RWD");

        staking = new Staking(
            address(stakeToken),
            address(rewardToken),
            REWARD_RATE
        );

        // Mint tokens
        stakeToken.mint(alice, 1_000 ether);
        stakeToken.mint(bob, 1_000 ether);

        rewardToken.mint(address(staking), 1_000_000 ether);

        // Approvals
        vm.prank(alice);
        stakeToken.approve(address(staking), type(uint256).max);

        vm.prank(bob);
        stakeToken.approve(address(staking), type(uint256).max);
    }


    function test_stakeupdatesbalance() public {
        vm.prank(alice);
        staking.stake(100 ether);

        assertEq(staking.staked(alice), 100 ether);
        assertEq(staking.totalstaked(), 100 ether);
    }

    function test_withdrawreducestake() public {
        vm.prank(alice);
        staking.stake(100 ether);

        vm.prank(alice);
        staking.withdraw(40 ether);

        assertEq(staking.staked(alice), 60 ether);
        assertEq(staking.totalstaked(), 60 ether);
    }


    function test_singleUserEarnsRewardsOverTime() public {
        vm.prank(alice);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 10);

        uint256 pending = staking.pendingreward(alice);
        assertApproxEqAbs(pending, 100 ether, 1);
    }

    function test_TwoUsersFairRewardDistribution() public {
        vm.prank(alice);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 10);

        vm.prank(bob);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 10);

        uint256 aliceRewards = staking.pendingreward(alice);
        uint256 bobRewards = staking.pendingreward(bob);

        assertApproxEqAbs(aliceRewards, 150 ether, 1);
        assertApproxEqAbs(bobRewards, 50 ether, 1);
    }


    function test_ClaimTransfersRewards() public {
        vm.prank(alice);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 10);

        uint256 before = rewardToken.balanceOf(alice);

        vm.prank(alice);
        staking.claimrewards();

        uint256 afterBal = rewardToken.balanceOf(alice);

        assertGt(afterBal, before);
    }

    function test_CannotClaimZeroRewards() public {
        vm.prank(alice);
        staking.stake(100 ether);

        vm.prank(alice);
        vm.expectRevert("no rewards");
        staking.claimrewards();
    }

    function test_WithdrawPaysPendingRewards() public {
        vm.prank(alice);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 10);

        uint256 rewardBefore = rewardToken.balanceOf(alice);

        vm.prank(alice);
        staking.withdraw(50 ether);

        uint256 rewardAfter = rewardToken.balanceOf(alice);

        assertGt(rewardAfter, rewardBefore);
        assertEq(staking.staked(alice), 50 ether);
    }


    function test_AdminCanSlashUser() public {
        vm.prank(alice);
        staking.stake(100 ether);

        staking.slash(alice, 30 ether);

        assertEq(staking.staked(alice), 70 ether);
        assertEq(staking.totalstaked(), 70 ether);
    }

    function test_NonAdminCannotSlash() public {
        vm.prank(alice);
        staking.stake(100 ether);

        vm.prank(bob);
        vm.expectRevert("not admin");
        staking.slash(alice, 10 ether);
    }
}
