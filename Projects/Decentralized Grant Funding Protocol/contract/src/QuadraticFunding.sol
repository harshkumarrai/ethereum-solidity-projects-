// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract QuadraticFunding {
    function calculateMatch(
        uint256[] calldata contributions
    ) external pure returns (uint256) {
        uint256 sumOfRoots;
        uint256 directSum;

        for (uint256 i = 0; i < contributions.length; i++) {
            uint256 c = contributions[i];
            directSum += c;
            sumOfRoots += _sqrt(c);
        }

        uint256 matched = (sumOfRoots * sumOfRoots) - directSum;
        return matched;
    }

    // Babylonian method
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
