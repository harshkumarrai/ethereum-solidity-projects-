// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20FundingVault {
    mapping(uint256 => mapping(address => uint256)) public contributions;

    function fundERC20(
        uint256 grantId,
        address token,
        uint256 amount
    ) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        contributions[grantId][msg.sender] += amount;
    }
}
