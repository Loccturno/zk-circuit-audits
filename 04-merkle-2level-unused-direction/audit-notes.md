# Audit Notes — Merkle 2-Level (Unused `direction1`)

## Overview

A 2-level Merkle membership circuit. The leaf has a path of 2 directions — one 
per tree level. Each level should hash its current value with its sibling, in 
the order determined by the direction bit.

---

## Finding 1 — `direction1` Declared and Boolean-Checked but Unused

**Severity**: High (DoS) — Critical (if positions affect external logic)

**Description**:
At level 1, the circuit always places `hash0.out` on the left and `sibling1` on 
the right, **ignoring `direction1` entirely**:

```circom
component hash1 = Poseidon(2);
hash1.inputs[0] <== hash0.out;     // always left
hash1.inputs[1] <== sibling1;      // always right
```

The line `direction1 * (1 - direction1) === 0;` enforces `direction1 ∈ {0, 1}` 
but the value never participates in the actual hashing — it's a *dangling input*.

---

### Concrete impact: legitimate user blocked (DoS)

Consider a 4-leaf tree:

```
              root
             /    \
            H1     H2
           / \    / \
          A   B  C   D
```

Where `H1 = hash(A,B)`, `H2 = hash(C,D)`, and `root = hash(H1, H2)`.

**Legitimate user wants to prove membership of `C`:**
- `leaf = C`
- `sibling0 = D`, `direction0 = 0` (C is on the left at level 0)
- After level 0: intermediate = `hash(C, D) = H2`
- `sibling1 = H1`, `direction1 = 1` (H2 is on the RIGHT at level 1)
- True root: `hash(H1, H2)`

**Buggy circuit computes:**
```
hash1.inputs[0] = hash0.out = H2
hash1.inputs[1] = sibling1 = H1
final = hash(H2, H1)
```

Since Poseidon is non-commutative: `hash(H2, H1) ≠ hash(H1, H2) = root`.

The comparison `hash1.out === root` fails. **The legitimate user cannot prove 
membership.** In a balanced tree, this affects approximately half of all leaves.

---

### Concrete impact: position spoofing

For leaves where the buggy ordering accidentally matches the real tree (e.g., 
leaves whose true `direction1 = 0`), the prover can supply **any** `direction1` 
value and still produce a valid proof. The `direction1` bit no longer carries 
positional information.

If any external system depends on the direction bits (nullifier derivation, 
voting weight, role assignment), the prover can manipulate those derivations 
freely. In Tornado-style systems where the nullifier depends on path bits, 
the same deposit can produce multiple distinct nullifiers → **double spend**.

---

## Fix

Apply the same conditional swap pattern used at level 0:

```circom
signal level1_in0;
signal level1_in1;
level1_in0 <== (1 - direction1) * hash0.out + direction1 * sibling1;
level1_in1 <== (1 - direction1) * sibling1 + direction1 * hash0.out;

component hash1 = Poseidon(2);
hash1.inputs[0] <== level1_in0;
hash1.inputs[1] <== level1_in1;
```

---

## Pattern Family

This is a generalization of two earlier bug classes:
- "Public input never used in constraint" (decorative public input — Exercise 02)
- "Component computed but not constrained" (decorative computation — SimpleWithdraw)

Both fall under: **declared structure that produces no actual checks**.

### Mental rule

**Every input must appear in at least one constraint beyond its own validity 
check (boolean, range, etc.). If an input only appears in `x * (1-x) === 0` 
and nowhere else, it's unused.**

Boolean checks alone are necessary but not sufficient — they confirm a value's 
*shape*, not that the value *does anything*.
