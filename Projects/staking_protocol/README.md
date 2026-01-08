# Staking Protocol with Rewards and Slashing

This project implements a production-style ERC20 staking protocol that allows users to stake tokens and earn rewards over time. The contract is designed with scalability and correctness in mind and follows industry-standard DeFi patterns used by protocols like Aave and Compound.

The core focus of this project is reward accounting, time-based fairness, and safe state transitions rather than frontend integration or upgradeability.

---

## Overview

Users stake an ERC20 token into the contract and earn rewards that accrue over time. Rewards are distributed proportionally based on how much a user has staked and for how long they have been staking.

Instead of updating rewards continuously for each user, the contract uses a global reward index that updates only when users interact with the system. This makes the protocol gas-efficient and scalable even with a large number of users.

An admin-controlled slashing mechanism is included to demonstrate how penalties can be enforced in staking systems.

---

## Reward Accounting Model

The protocol uses index-based reward accounting.

A global variable tracks how many reward tokens have accrued per staked token so far. Each user stores a snapshot of this value at the time of their last interaction. When a user stakes, withdraws, or claims rewards, their pending rewards are calculated as the difference between the current global index and their stored snapshot.

This approach avoids loops, prevents per-block updates, and ensures that rewards are distributed fairly based on stake amount and time.

---

## Core Functionality

Users can stake ERC20 tokens to start earning rewards. They may withdraw part or all of their stake at any time, and any pending rewards are settled before the withdrawal is processed.

Users can also claim rewards independently without modifying their staked balance.

The contract owner has the ability to slash a user’s stake. Slashing reduces the user’s staked amount and updates global accounting to maintain fairness for remaining participants.

---

## Security and Design Choices

The contract follows the Checks-Effects-Interactions pattern to prevent common vulnerabilities such as reentrancy and incorrect state updates.

Reward settlement always happens before stake balances are modified, ensuring that users do not lose rewards during stake or withdrawal operations.

The design intentionally avoids upgradeability, pausing logic, and multiple reward tokens in order to keep the system simple, auditable, and focused on core staking mechanics.

---

## Testing

The protocol is thoroughly tested using Foundry.

Tests cover single-user and multi-user staking scenarios, time-based reward accrual, fair reward distribution when users join at different times, reward claiming, partial withdrawals, and admin-only slashing behavior.

Time manipulation is performed using vm.warp to validate correctness across different staking durations.

All tests can be run locally using:

forge test

---

## Tech Stack

The project is written in Solidity and tested using Foundry. OpenZeppelin ERC20 contracts are used for token interactions.

---

## Notes

This project is intended to demonstrate protocol-level smart contract design rather than frontend integration. The emphasis is on correctness, scalability, and clean accounting logic.

