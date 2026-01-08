// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GrantRegistry {
    enum GrantStatus {
        Created,
        Funding,
        Review,
        Approved,
        Rejected
    }

    struct Grant {
        address creator;
        string metadataURI; // IPFS hash
        uint256 deadline;
        GrantStatus status;
    }

    uint256 public grantCount;
    mapping(uint256 => Grant) public grants;

    event GrantCreated(uint256 indexed grantId, address indexed creator);
    event GrantStatusUpdated(uint256 indexed grantId, GrantStatus status);

    modifier onlyCreator(uint256 grantId) {
        require(msg.sender == grants[grantId].creator, "Not creator");
        _;
    }

    function createGrant(
        string calldata _metadataURI,
        uint256 _deadline
    ) external returns (uint256) {
        require(_deadline > block.timestamp, "Invalid deadline");

        grantCount++;
        grants[grantCount] = Grant({
            creator: msg.sender,
            metadataURI: _metadataURI,
            deadline: _deadline,
            status: GrantStatus.Created
        });

        emit GrantCreated(grantCount, msg.sender);
        return grantCount;
    }

    function moveToFunding(uint256 grantId) external onlyCreator(grantId) {
        Grant storage g = grants[grantId];
        require(g.status == GrantStatus.Created, "Invalid state");
        g.status = GrantStatus.Funding;

        emit GrantStatusUpdated(grantId, GrantStatus.Funding);
    }

    function moveToReview(uint256 grantId) external {
        Grant storage g = grants[grantId];
        require(block.timestamp >= g.deadline, "Funding still active");
        require(g.status == GrantStatus.Funding, "Invalid state");

        g.status = GrantStatus.Review;
        emit GrantStatusUpdated(grantId, GrantStatus.Review);
    }

    function finalizeGrant(uint256 grantId, bool approved) external {
        // ⚠️ This will later be restricted to Governance
        Grant storage g = grants[grantId];
        require(g.status == GrantStatus.Review, "Invalid state");

        g.status = approved ? GrantStatus.Approved : GrantStatus.Rejected;
        emit GrantStatusUpdated(grantId, g.status);
    }
}
