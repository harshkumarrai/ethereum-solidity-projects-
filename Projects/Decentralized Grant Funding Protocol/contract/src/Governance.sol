// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GrantRegistry.sol";

contract Governance {
    GrantRegistry public immutable registry;

    struct Vote {
        uint256 yes;
        uint256 no;
        uint256 end;
        bool executed;
    }

    mapping(uint256 => Vote) public votes;

    constructor(address _registry) {
        registry = GrantRegistry(_registry);
    }

    function createVote(uint256 grantId) external {
        votes[grantId] = Vote({
            yes: 0,
            no: 0,
            end: block.timestamp + 3 days,
            executed: false
        });
    }

    function vote(uint256 grantId, bool support) external {
        Vote storage v = votes[grantId];
        require(block.timestamp < v.end, "Voting ended");

        // ⚠️ Simplified voting (can upgrade to token-based)
        if (support) v.yes++;
        else v.no++;
    }

    function execute(uint256 grantId) external {
        Vote storage v = votes[grantId];
        require(block.timestamp >= v.end, "Voting active");
        require(!v.executed, "Executed");

        v.executed = true;
        bool approved = v.yes > v.no;

        registry.finalizeGrant(grantId, approved);
    }
}
