# zk-circuit-audits

A growing collection of Circom circuit audits — vulnerable contracts, fixed versions, 
and detailed audit notes.

Each folder contains:
- The vulnerable circuit (`*.circom`)
- The patched version (`*Fixed.circom`)
- An audit note (`audit-notes.md`) with Severity / Description / Impact / Fix

Part of my path toward ZK & smart contract auditing.

## Exercises

### [01 — SimpleWithdraw](./01-simple-withdraw/)
A privacy-pool withdrawal circuit with multiple bugs in the same template:
- Unconstrained nullifier output (`<--` vs `<==`)
- Missing underflow check on balance subtraction
- Disconnect between private `amount` and public `withdrawAmount`
- Architectural flaw: `userBalance` not bound to the commitment

### [02 — Merkle 1-Level: Missing Root Constraint](./02-merkle-1level-missing-root/)
The circuit computes a Merkle hash correctly but forgets to constrain it 
against the expected root. The `root` public input becomes decorative.

### [03 — Merkle 1-Level: Missing Boolean Check](./03-merkle-1level-boolean-check/)
The conditional swap uses a `direction` bit without enforcing it to be 
strictly 0 or 1, expanding the prover's search space.

### [04 — Merkle 2-Level: Unused Direction Bit](./04-merkle-2level-unused-direction/)
`direction1` is declared and boolean-checked, but never participates in 
the level-1 hashing. A dangling input that produces no actual constraint.

## Pattern Library

Recurring Circom bugs across these exercises:

| Pattern | What it looks like | Fix |
|---------|-------------------|------|
| **`<--` without follow-up constraint** | `nullifier <-- computeNullifier.out;` | Use `<==` for assignment + constraint |
| **Output never constrained** | `signal output y;` with only `<--` writes to it | Replace `<--` with `<==`, or add explicit `===` |
| **Public input never used in constraint** | `signal input root;` declared but `root` never appears in `===` | Add `hasher.out === root;` |
| **Missing boolean check** | `direction` used in arithmetic without `direction * (1 - direction) === 0` | Add the boolean constraint |
| **Dangling input** | Input declared, boolean-checked, but unused in main logic | Use it in the actual computation or remove |
| **Underflow on subtraction** | `result <== a - b;` without checking `a >= b` | Add `GreaterEqThan` comparator |
| **Private/public disconnect** | Two related signals (one private, one public) never linked by `===` | Constrain them equal: `private === public` |

## Mental rules for auditing Circom

1. **Ctrl+F every `<--`**. If you see one, find the matching `===` nearby. If absent, it's a bug.
2. **Ctrl+F every `signal input`**. Each one must appear in at least one constraint beyond its boolean check.
3. **Any field subtraction needs a range check.** Field arithmetic wraps around silently.
4. **Public input that doesn't appear in `===`** is decorative — the prover sets it freely.
5. **Output signals that are written with `<--` only** are prover-controlled.

## License

MIT
