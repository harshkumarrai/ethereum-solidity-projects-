pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../src/vesting/TokenVesting.sol";
contract MockERC20 is ERC20{
    constructor()ERC20("MockToken","MOCK"){
        _mint(msg.sender,1_000_000 ether);
    }

}

contract TokenVestingTest is Test{
    MockERC20 token;
    TokenVesting vesting;
    address beneficiary=address(0xBEEF);
    uint64 start;
    uint64 cliffduration=30 days;
    uint64 duration=180 days;

    function setUp()public {
        token=new MockERC20();
        start=uint64(block.timestamp);
        vesting=new TokenVesting(
            address(token),
            beneficiary,
            start,
            cliffduration,
            duration
        );
        require(token.transfer(address(vesting),1_000_000 ether),"trasfer failed");
    }

}
