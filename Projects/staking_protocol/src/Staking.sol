// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
   IERC20 public immutable staketoken;
   IERC20 public immutable rewardtoken;
   uint256 public rewardrate;  //gives inf in each secon how much reward tokens are generated
   uint256 public lastupdatedtime;  // gives inf about time when updates where done
    uint256 public accrewardpershare;  //how much reward in each share
   uint256 public totalstaked;
   mapping(address=>uint256)public staked; 
   mapping(address=>uint256)public currentreward;  //rewarddebt
   address public admin;
   constructor(
    address _stakingtoken,
    address _rewardtoken,
    uint256 _rewardrate
   ){
        staketoken= IERC20(_stakingtoken);
        rewardtoken=IERC20(_rewardtoken);
        rewardrate=_rewardrate;
        lastupdatedtime=block.timestamp;
        admin=msg.sender;
   }
   modifier onlyadmin(){
    require(msg.sender==admin,"not admin");
    _;
   }
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
        event RewardClaimed(address indexed user, uint256 amount);
    event Slashed(address indexed user, uint256 amount);

   function updatereward() internal{
    if(block.timestamp<lastupdatedtime)return;
    if(totalstaked==0){
        lastupdatedtime=block.timestamp;
        return;
    }
    uint256 timelapsed=block.timestamp-lastupdatedtime;
    uint256 rewards=timelapsed*rewardrate;
    accrewardpershare+=((rewards*1e18)/totalstaked);
    lastupdatedtime=block.timestamp;
   }
   function pendingreward(address user) public view returns(uint256){
    uint256 temp1=accrewardpershare;
    if(block.timestamp>lastupdatedtime && totalstaked>0 ){
        uint256 timeelapsed=block.timestamp-lastupdatedtime;
        uint256 rewards=(timeelapsed*rewardrate);
        temp1+=(rewards*1e18)/totalstaked;
    }
    return (staked[user]*temp1)/1e18 - currentreward[user];

   }
   function stake(uint256 amount)external{
            require(amount > 0, "zero amount");

        updatereward();

    
        uint256 pending = pendingreward(msg.sender);
        if (pending > 0) {
            rewardtoken.transfer(msg.sender, pending);
            emit RewardClaimed(msg.sender, pending);
        }

        staketoken.transferFrom(msg.sender, address(this), amount);

        totalstaked += amount;
        staked[msg.sender] += amount;
        currentreward[msg.sender] =
            (staked[msg.sender] * accrewardpershare) /
            1e18;

        emit Staked(msg.sender, amount);
   }
   
        function withdraw(uint256 amount) external {
        require(amount > 0, "zero amount");
        require(staked[msg.sender] >= amount, "insufficient stake");

        updatereward();

        uint256 pending = pendingreward(msg.sender);
        if (pending > 0) {
            rewardtoken.transfer(msg.sender, pending);
            emit RewardClaimed(msg.sender, pending);
        }

        staked[msg.sender] -= amount;
        totalstaked -= amount;

        staketoken.transfer(msg.sender, amount);

        currentreward[msg.sender] =
            (staked[msg.sender] * accrewardpershare) /
            1e18;

        emit Withdrawn(msg.sender, amount);
    }

    function claimrewards() external {
        updatereward();

        uint256 pending = pendingreward(msg.sender);
        require(pending > 0, "no rewards");

        currentreward[msg.sender] =
            (staked[msg.sender] * accrewardpershare) /
            1e18;

        rewardtoken.transfer(msg.sender, pending);
        emit RewardClaimed(msg.sender, pending);
    }

   
    function slash(address user, uint256 amount) external onlyadmin() {
        require(staked[user] >= amount, "slash too much");

        updatereward();

        staked[user] -= amount;
        totalstaked -= amount;

      currentreward  [user] =
            (staked[user] * accrewardpershare) /
            1e18;

        emit Slashed(user, amount);
    }
}