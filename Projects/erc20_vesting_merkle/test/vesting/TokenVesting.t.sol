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
    MerkelVesting vesting;
    address beneficiary=address(0xBEEF);  //user
    address attacker = address(0xCAFE); //malicious user
    uint256 allocation=100_000 ether;
    uint64 start;
    uint64 cliffduration=30 days;
    uint64 duration=180 days;
    bytes32 root;
    bytes32[] proof;  //empty as proof means path from lef to root ,  as one leaf is there so empty proof
    function setUp()public {
        token=new MockERC20();
        start=uint64(block.timestamp);
        bytes32 leaf=keccak256(abi.encodePacked(beneficiary,allocation));
        // as there is single leaf so root will be same to leaf;
        root=leaf;
        vesting=new MerkelVesting(
            address(token),
            root,
            start,
            cliffduration,
            duration
        );
        require(token.transfer(address(vesting),allocation),"trasfer failed");
    }
    //testing claim function
    function test_Claim() public {
        vm.prank(beneficiary);
        vesting.claim(allocation,proof);
        uint256 temp1=vesting.totalallocation(beneficiary);
        assertEq(temp1, allocation);

    }
    function test_Revertinvalidproof() public{
         vm.prank(beneficiary);
         vm.expectRevert("invalid proof");
        vesting.claim(allocation+1,proof);

    }


    function test_RevertdoubleClaim() public {
        vm.prank(beneficiary);
        vesting.claim(allocation, proof);

        vm.prank(beneficiary);
        vm.expectRevert("already claimed");
        vesting.claim(allocation, proof);
    }

    //testing vestedamount and releasable functions
    function test_ReleasableBeforeCliffIsZero() public {
        vm.prank(beneficiary);
        vesting.claim(allocation, proof);

        vm.warp(start + 10 days);
        uint256 releasable = vesting.releasable(beneficiary);

        assertEq(releasable, 0);
    }

    function test_ReleasableAtCliffIsNonZero() public {
        vm.prank(beneficiary);
        vesting.claim(allocation, proof);

        vm.warp(start + cliffduration);
        uint256 releasable = vesting.releasable(beneficiary);

        assertGt(releasable, 0);
    }

    function test_PartialVestingMidway() public {
        vm.prank(beneficiary);
        vesting.claim(allocation, proof);

        vm.warp(start + 90 days);

        uint256 releasable = vesting.releasable(beneficiary);
        uint256 expected = (allocation * 90 days) / duration;

        assertEq(releasable, expected);
    }

    function test_FullVestingAfterDuration() public {
        vm.prank(beneficiary);
        vesting.claim(allocation, proof);

        vm.warp(start + duration);

        uint256 releasable = vesting.releasable(beneficiary);
        assertEq(releasable, allocation);
    }

    //testing release function
      function test_ReleaseTransfersTokens() public {
        vm.prank(beneficiary);
        vesting.claim(allocation, proof);

        vm.warp(start + cliffduration + 10 days);

        uint256 before = token.balanceOf(beneficiary);

        vm.prank(beneficiary);
        vesting.release();

        uint256 afterBalance = token.balanceOf(beneficiary);
        assertGt(afterBalance, before);
    }

    function test_RevertReleaseBeforeClaim() public {
        vm.prank(beneficiary);
        vm.expectRevert("nothing to release");
        vesting.release();
    }

    function test_NoDoubleRelease() public {
        vm.prank(beneficiary);
        vesting.claim(allocation, proof);

        vm.warp(start + 60 days);
        vm.prank(beneficiary);
        vesting.release();

        uint256 firstRelease = token.balanceOf(beneficiary);

        vm.warp(start + 120 days);
        vm.prank(beneficiary);
        vesting.release();

        uint256 secondRelease = token.balanceOf(beneficiary);

        assertGt(secondRelease, firstRelease);
        assertLe(secondRelease, allocation);
    }

    //testing that attacker who is not in merkle tree cannot claim or release tokens
     function test_Attacker() public {
        vm.prank(beneficiary);
        vesting.claim(allocation, proof);

        vm.warp(start + duration);

        vm.prank(attacker);
        vm.expectRevert("nothing to release");
        vesting.release();
    }
    
}
