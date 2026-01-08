// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    uint256 public rewardRate; // rewards per second
    uint256 public lastUpdateTime;
    uint256 public accRewardPerShare; // scaled by 1e18

    uint256 public totalStaked;

    mapping(address => uint256) public staked;
    mapping(address => uint256) public rewardDebt;

    address public admin;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event Slashed(address indexed user, uint256 amount);

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRate
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
        admin = msg.sender;
    }


    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }


    function _updateRewards() internal {
        if (block.timestamp <= lastUpdateTime) return;

        if (totalStaked == 0) {
            lastUpdateTime = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        uint256 rewards = timeElapsed * rewardRate;

        accRewardPerShare += (rewards * 1e18) / totalStaked;
        lastUpdateTime = block.timestamp;
    }

    function pendingRewards(address user) public view returns (uint256) {
        uint256 _accRewardPerShare = accRewardPerShare;

        if (block.timestamp > lastUpdateTime && totalStaked > 0) {
            uint256 timeElapsed = block.timestamp - lastUpdateTime;
            uint256 rewards = timeElapsed * rewardRate;
            _accRewardPerShare += (rewards * 1e18) / totalStaked;
        }

        return
            (staked[user] * _accRewardPerShare) / 1e18 -
            rewardDebt[user];
    }


    function stake(uint256 amount) external {
        require(amount > 0, "zero amount");

        _updateRewards();

    
        uint256 pending = pendingRewards(msg.sender);
        if (pending > 0) {
            rewardToken.transfer(msg.sender, pending);
            emit RewardClaimed(msg.sender, pending);
        }

        stakingToken.transferFrom(msg.sender, address(this), amount);

        totalStaked += amount;
        staked[msg.sender] += amount;
        rewardDebt[msg.sender] =
            (staked[msg.sender] * accRewardPerShare) /
            1e18;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "zero amount");
        require(staked[msg.sender] >= amount, "insufficient stake");

        _updateRewards();

        uint256 pending = pendingRewards(msg.sender);
        if (pending > 0) {
            rewardToken.transfer(msg.sender, pending);
            emit RewardClaimed(msg.sender, pending);
        }

        staked[msg.sender] -= amount;
        totalStaked -= amount;

        stakingToken.transfer(msg.sender, amount);

        rewardDebt[msg.sender] =
            (staked[msg.sender] * accRewardPerShare) /
            1e18;

        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() external {
        _updateRewards();

        uint256 pending = pendingRewards(msg.sender);
        require(pending > 0, "no rewards");

        rewardDebt[msg.sender] =
            (staked[msg.sender] * accRewardPerShare) /
            1e18;

        rewardToken.transfer(msg.sender, pending);
        emit RewardClaimed(msg.sender, pending);
    }

   
    function slash(address user, uint256 amount) external onlyAdmin {
        require(staked[user] >= amount, "slash too much");

        _updateRewards();

        staked[user] -= amount;
        totalStaked -= amount;

        rewardDebt[user] =
            (staked[user] * accRewardPerShare) /
            1e18;

        emit Slashed(user, amount);
    }
}
