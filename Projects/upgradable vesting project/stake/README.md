Upgradeable ERC20 Vesting Vault (UUPS)

This project implements an upgradeable ERC20 token vesting system using the UUPS proxy pattern in Solidity.

The goal was to understand how real Ethereum protocols safely upgrade smart contracts while preserving user state and funds.

 Problem

Smart contracts on Ethereum are immutable by default.
However, real-world protocols need to:

Fix bugs

Add new features

Improve security

Evolve over time

Redeploying contracts breaks user trust and state, so upgradeability must be handled carefully.

Solution

I built an ERC20 Vesting Vault that:

Uses the UUPS (Universal Upgradeable Proxy Standard) pattern

Supports cliff-based + linear vesting

Allows controlled upgrades without losing state

Enforces upgrade authorization using ownership

Architecture Overview

Proxy: ERC1967Proxy

Implementation (V1): VestingVault

Upgraded Logic (V2): VestingVaultV2

Upgrade Mechanism: UUPS (upgradeTo)

State Storage: Lives in proxy, not implementation

Features

Create vesting schedules for beneficiaries

Cliff period before tokens start unlocking

Linear token release over time

Beneficiaries can claim vested tokens

Owner can revoke unvested tokens

Safe contract upgrades (V1 → V2)

State preserved across upgrades

 Upgrade Flow (V1 → V2)

Deploy VestingVault (implementation)

Deploy ERC1967Proxy pointing to V1

Initialize via initialize() (no constructors)

Deploy VestingVaultV2

Call upgradeTo(newImplementation) from proxy owner

Verify that existing vesting data remains intact

🧪 Testing

Written using Foundry

Covers:

Vesting creation

Token release after cliff

Revocation logic

Upgrade safety & state preservation

Run tests:

forge test

Deployment

Deployed on Sepolia testnet using Foundry scripts.

Implementation & Proxy deployed

Contracts verified

Upgrade executed on-chain using upgradeTo

🛠 Tech Stack

Solidity ^0.8.x

OpenZeppelin Contracts & Upgradeable

Foundry (testing & deployment)

ERC1967 + UUPS pattern

Sepolia Testnet

Key Learnings

Why initialize() replaces constructors in upgradeable contracts

How delegatecall affects storage layout

How UUPS restricts upgrades to authorized accounts

Why storage compatibility is critical

How production protocols manage upgrades safely

🔗 Links

GitHub Repo: https://github.com/harshkumarrai/ethereum-solidity-projects-

Focus: Smart contract architecture & upgrade safety

Frontend: Minimal UI for interaction (contract-focused project)

 Notes

This project intentionally focuses on backend smart contract design.
