# ERC20 Merkle Vesting

A gas-efficient ERC20 vesting contract that uses Merkle proofs to verify user
allocations and applies a global time-based vesting schedule.

## Overview
This contract enables large-scale token distributions by storing only a single
Merkle root on-chain. Eligible users prove their allocation using a Merkle proof
and receive tokens gradually according to a cliff and linear vesting schedule.

## Features
- Merkle proof–based allocation verification
- One-time claim per user
- Global vesting schedule (start, cliff, duration)
- Linear vesting with secure release logic
- Protection against double claim and early release
- Comprehensive Foundry test suite

## Design Decisions
- **Fixed Merkle root**: prevents late joiners and minimizes trust assumptions
- **Global vesting schedule**: reduces gas cost and complexity
- **No admin mutation**: improves immutability and auditability

## Claim & Release Flow
1. Contract is deployed with a Merkle root
2. Tokens are funded to the contract
3. Users claim allocation using Merkle proof
4. Tokens vest over time and can be released gradually

## Tech Stack
- Solidity
- Foundry
- OpenZeppelin (IERC20, MerkleProof)

## Testing
Tests cover:
- Valid and invalid Merkle proofs
- Double claim prevention
- Vesting before cliff, mid-vesting, and after duration
- Release safety and accounting correctness
