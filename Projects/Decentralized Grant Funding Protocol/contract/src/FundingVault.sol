// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GrantRegistry.sol";

contract FundingVault {
    GrantRegistry public immutable registry;

    mapping(uint256 => uint256) public totalFunds;
    mapping(uint256 => mapping(address => uint256)) public contributions;

    event Funded(uint256 indexed grantId, address indexed user, uint256 amount);
    event Withdrawn(uint256 indexed grantId, address indexed to, uint256 amount);
    event Refunded(uint256 indexed grantId, address indexed to, uint256 amount);

    constructor(address _registry) {
        registry = GrantRegistry(_registry);
    }

    function fundGrant(uint256 grantId) external payable {
        (, , , GrantRegistry.GrantStatus status) = registry.grants(grantId);
        require(status == GrantRegistry.GrantStatus.Funding, "Not funding");

        contributions[grantId][msg.sender] += msg.value;
        totalFunds[grantId] += msg.value;

        emit Funded(grantId, msg.sender, msg.value);
    }

    function withdraw(uint256 grantId) external {
        (
            address creator,
            ,
            ,
            GrantRegistry.GrantStatus status
        ) = registry.grants(grantId);

        require(status == GrantRegistry.GrantStatus.Approved, "Not approved");
        require(msg.sender == creator, "Not creator");

        uint256 amount = totalFunds[grantId];
        totalFunds[grantId] = 0;

        (bool ok,) = creator.call{value: amount}("");
        require(ok, "ETH transfer failed");

        emit Withdrawn(grantId, creator, amount);
    }

    function refund(uint256 grantId) external {
        (, , , GrantRegistry.GrantStatus status) = registry.grants(grantId);
        require(status == GrantRegistry.GrantStatus.Rejected, "Not rejected");

        uint256 contributed = contributions[grantId][msg.sender];
        require(contributed > 0, "Nothing to refund");

        contributions[grantId][msg.sender] = 0;

        (bool ok,) = msg.sender.call{value: contributed}("");
        require(ok, "ETH transfer failed");

        emit Refunded(grantId, msg.sender, contributed);
    }
}
