# Audit Notes — Merkle Leaf (1-Level, Missing Root Constraint)

## Overview

A simplified Merkle membership circuit for a 2-leaf tree. The prover claims to 
know a leaf at the left position and its right sibling; the verifier should 
check that hashing them produces the expected root.

---

## Finding 1 — Public Input `root` Never Constrained

**Severity**: Critical

**Description**:
The circuit computes `Poseidon(leaf, sibling)` correctly, but **never compares 
the result against the public input `root`**. The line `hasher.out === root;` 
is missing.

```circom
component hasher = Poseidon(2);
hasher.inputs[0] <== leaf;
hasher.inputs[1] <== sibling;
// hasher.out === root;  ← MISSING
```

**Impact**:
The `root` becomes a "decorative input" — declared, accepted by the verifier, 
but **irrelevant to validation**. A prover can supply any `leaf`, any `sibling`, 
and any `root`, and the proof will pass. The verifier learns nothing about 
whether `leaf` is actually a member of any specific tree.

This is the same bug class as Finding 1 in SimpleWithdraw (`<--` instead of `<==`), 
just in a different shape: **computed value never bound to expected value**.

**Fix**:
```circom
hasher.out === root;
```

---

## Lesson

Every public input must appear in at least one constraint (`===` or `<==`) inside 
the circuit. If a public input is declared but never used, the prover gets to 
set it freely — the verifier's "expected value" carries no weight.

### Mental rule

**Ctrl+F every `signal input` declared as `public`. If it appears only in the 
declaration and never inside a constraint, it is decorative.**

A public input that doesn't appear in `===` is *cosmetic*, not load-bearing.
