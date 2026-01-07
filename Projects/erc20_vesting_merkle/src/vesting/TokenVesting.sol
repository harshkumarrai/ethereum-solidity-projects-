pragma solidity ^0.8.0;     
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";
contract TokenVesting{
    
//no help plss
    IERC20 public immutable token;
    address public immutable beneficiary;
    uint64 public immutable start;
    uint64 public immutable cliff;
    uint64 public immutable duration;
    uint256 public released;
    constructor(
        address _token,
        address _beneficiary,
        uint64 _start,
        uint64 __cliffDuration,
        uint64 _duration
    ){
        require(_beneficiary !=address(0),"invalid beneficiary");
        require(__cliffDuration <=_duration ,"cliff>duration");
        token=IERC20(_token);
        beneficiary=_beneficiary;
        start=_start;
        cliff=start+__cliffDuration;
        duration=_duration;
    }

    function vestedAmount() public view returns (uint256){ // it helps to find how much tokens r vested till now
        uint256 total=token.balanceOf(address(this))+released;
        console.log( "hahaha" ,total);
        if(block.timestamp<cliff){
            return 0;
        }else if(block.timestamp>=(start+duration)){
            return total;
        }else {
            uint256 vestedTime=block.timestamp-start;
            return (total*vestedTime)/duration;
        }
    }
    function releasable() public view returns (uint256){  // it helps to find how mich token we can pull out now
    // console.log( "hahaha" ,vestedAmount());
        return vestedAmount()-released;
        
    }
    function release() external{  //find how much token to release;
        uint256 amount=releasable();
        require((amount>0),"nothing to release");
        released+=amount;
        require(token.transfer(beneficiary,amount),"transfer failed");
    }
 
}