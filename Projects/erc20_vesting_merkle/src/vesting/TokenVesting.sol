pragma solidity ^0.8.20 ;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
contract MerkelVesting{
    IERC20 public immutable token;
    bytes32 public immutable merkleroot;
    uint64 public immutable start;
    uint64 public immutable cliff;
    uint64 public immutable duration;
    mapping(address=>uint256)public totalallocation;
    mapping(address=>uint256)public released;

    constructor(
        address _token,
        bytes32 _merkleroot,
        uint64 _start,
        uint64 _cliffduration,
        uint64 _duration
    ){
        // console.log("cliffduration",_cliffduration);
        require(_cliffduration <=_duration, "cliff is more than duration");
        token=IERC20(_token);
        merkleroot=_merkleroot;
        start=_start;
        cliff=start+_cliffduration;
        duration=_duration;

    }
    //claims fucntion helps the user to  prove that he is eligible for vesting and his allocation is this  and it register
    //it self in vesting contract.  before calling claim function the the contract knows nothing about user
    //
    function claim(
        uint256 amount,
        bytes32[] calldata proof
    )external {
        require(totalallocation[msg.sender]==0 ,"already claimed");
        bytes32 leaf= keccak256(abi.encodePacked(msg.sender,amount));
        require(
            MerkleProof.verify(proof,merkleroot, leaf),"invalid proof"
        );
        totalallocation[msg.sender]=amount;
    }
     function releasable(address user)public view  returns(uint256){
        return vestedamount(user)-released[user];
     }
     function vestedamount(address user)public view returns(uint256){
        uint256 total = totalallocation[user];
        if(total==0)return 0;
        if(block.timestamp<cliff)return 0;
        if(block.timestamp>=(start+duration))return total;
        uint256 temp1= block.timestamp-start;
        uint256 temp2= temp1*(total)/duration;
        return temp2;
     }
     function release() external{
        uint amount=releasable(msg.sender);
        require(amount>0 ,"nothing to release");
        released[msg.sender]+=amount;
        require(token.transfer(msg.sender,amount),"transaction failed");

     }
}