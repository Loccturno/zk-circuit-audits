# Audit Notes — SimpleWithdraw

## Overview

A privacy-pool withdrawal circuit. The user proves three things in one ZK proof:
1. They know the secret behind a registered commitment
2. They produce a unique nullifier (so each deposit can be withdrawn only once)
3. They have enough balance for the withdrawal

The circuit contains **3 critical/high findings plus 1 architectural flaw**.

---

## Finding 1 — Unconstrained Nullifier Output

**Severity**: Critical

**Description**:
```circom
nullifier <-- computeNullifier.out;
```
The line uses `<--` (assignment only) instead of `<==` (assignment + constraint). 
The nullifier output is **not bound** to the computed Poseidon hash.

**Impact**:
A malicious prover can set `nullifier` to any arbitrary value when generating 
the proof. This **completely breaks** the anti-double-spend mechanism: the same 
commitment can be withdrawn unlimited times, each generating a different 
attacker-chosen nullifier that the on-chain contract has never seen before.

**Fix**:
```circom
nullifier <== computeNullifier.out;
```

---

## Finding 2 — Missing Underflow Check

**Severity**: High

**Description**:
```circom
newBalance <== userBalance - amount;
```
The subtraction has no range check. In a finite field, when `amount > userBalance`, 
the result wraps around to a number near 2²⁵³ (the field prime), effectively 
granting the prover a near-infinite balance.

**Impact**:
A prover can withdraw amounts vastly exceeding their actual deposit. The contract 
sees a "valid" `newBalance` and processes the withdrawal as if it were legitimate.

**Fix**:
```circom
component balanceCheck = GreaterEqThan(64);
balanceCheck.in[0] <== userBalance;
balanceCheck.in[1] <== amount;
balanceCheck.out === 1;
```

---

## Finding 3 — Private `amount` Disconnected from Public `withdrawAmount`

**Severity**: Critical

**Description**:
- `amount` (private) is what gets subtracted from the user's balance.
- `withdrawAmount` (public) is what the on-chain contract pays out.
- **There is no constraint linking the two values.**

**Impact**:
A prover sets `amount = 1` (subtract 1 from balance) but `withdrawAmount = 1000` 
(contract pays 1000). The proof is valid, the contract pays 1000, the prover 
repeats indefinitely with almost no balance reduction.

**Fix**:
```circom
amount === withdrawAmount;
```

---

## Finding 4 — `userBalance` Not Bound to Commitment

**Severity**: High (architectural)

**Description**:
The commitment is `Poseidon(secret)`, but `userBalance` is supplied separately 
as a private input with no link to the commitment. A prover can declare any 
balance regardless of what they actually deposited.

**Impact**:
Even with all other bugs fixed, the prover can simply set `userBalance = 1_000_000` 
and the commitment check passes (since it only verifies the secret).

**Fix**:
The commitment scheme itself must bind **both** secret AND balance:
```circom
component computeCommitment = Poseidon(2);
computeCommitment.inputs[0] <== secret;
computeCommitment.inputs[1] <== userBalance;
computeCommitment.out === commitmentHash;
```
This requires the on-chain commitment registration to also use 
`Poseidon(secret, balance)` when the user deposits.

---

## Summary

| # | Finding | Severity |
|---|---------|----------|
| 1 | Unconstrained nullifier output | **Critical** |
| 2 | Missing underflow check | **High** |
| 3 | `amount` / `withdrawAmount` disconnect | **Critical** |
| 4 | `userBalance` not bound to commitment | **High** (architectural) |

## Lessons Carried Forward

- Every output signal needs `<==` not `<--`. The latter is assignment-only and 
  hands the prover full control of the value.
- Every public input must appear in at least one constraint. Otherwise it's 
  "decorative" and the prover sets it freely.
- Field subtraction without a range check is an underflow waiting to happen.
- Commitment schemes must bind every value they claim to authenticate. 
  `Poseidon(secret)` cannot vouch for `userBalance` if `userBalance` isn't 
  inside the hash.
