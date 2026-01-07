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
    uint256 constant Total_Tokens=1_000_000 ether;

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
     function test_ReleasableBeforeCliff() public {
      vm.warp(start+10 days);
      uint256 releasable=vesting.releasable();
      assertEq(releasable,0);
    }
       function test_ReleasableAtCliff() public {
        vm.warp(start+cliffduration);
        uint256 releasable=vesting.releasable();
        console.log("jaa",releasable);
        assertGt(releasable,0);
        
    }
     function test_PartialVestingMidway() public {
        vm.warp(start+90 days);
        uint256 releasable=vesting.releasable();
        uint256 expected=(Total_Tokens * 90 days)/duration;
        assertEq(releasable, expected);
    }
     function test_FullVestingAfterDuration() public {
        vm.warp(start + duration);

        uint256 releasable = vesting.releasable();
        assertEq(releasable, Total_Tokens);
    }
      function test_ReleaseTransfersTokens() public {
        vm.warp(start + 90 days);

        uint256 beforeBalance = token.balanceOf(beneficiary);

        vesting.release();

        uint256 afterBalance = token.balanceOf(beneficiary);
        assertGt(afterBalance, beforeBalance);
    }

     function test_NoDoubleRelease() public {
        vm.warp(start + 90 days);
        vesting.release();

        uint256 firstRelease = token.balanceOf(beneficiary);

        vm.warp(start + 120 days);
        vesting.release();

        uint256 secondRelease = token.balanceOf(beneficiary);

        assertGt(secondRelease, firstRelease);
        assertLe(secondRelease, Total_Tokens);
    }
    function test_RevertIfNothingToRelease() public {
        vm.warp(start + 10 days);

        vm.expectRevert("nothing to release");
        vesting.release();
    }
}
