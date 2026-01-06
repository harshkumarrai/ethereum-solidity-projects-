pragma solidity ^0.8.20;
import "forge-std/Test.sol"
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20{
    constructor()ERC20("MockToken","MOCK"){
        _mint(msg.sender,1_000_000 ether);
    }
    
}
