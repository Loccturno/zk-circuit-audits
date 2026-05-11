# Audit Notes — Merkle Leaf with Direction (Missing Boolean Check)

## Overview

A 1-level Merkle membership circuit that uses a `direction` bit to determine 
whether the leaf is the left or right child. The conditional swap is implemented 
with branchless arithmetic (no `if/else`, since Circom doesn't support runtime 
branching).

---

## Finding 1 — `direction` Not Constrained to Boolean

**Severity**: High (in standalone) → Critical (in context)

**Description**:
The branchless swap:
```circom
in0 <== (1 - direction) * leaf + direction * sibling;
in1 <== (1 - direction) * sibling + direction * leaf;
```
mathematically performs the correct swap **only when `direction ∈ {0, 1}`**. 
The circuit does not enforce this — `direction` can be any field element.

### Numerical demonstration

With `leaf = 10`, `sibling = 20`:

| `direction` | `in0` | `in1` | Behavior |
|-------------|-------|-------|----------|
| 0 | 10 | 20 | ✓ leaf left, sibling right |
| 1 | 20 | 10 | ✓ swapped |
| 2 | -10 + 2·20 = 30 | -20 + 2·10 = 0 | ✗ garbage |
| 7 | -60 + 140 = 80 | -120 + 70 = -50 | ✗ garbage |

The circuit accepts these garbage values as valid inputs to the hash.

**Impact**:
A malicious prover can set `direction` to arbitrary field values, producing 
garbage `in0` and `in1` inputs to Poseidon. While these rarely produce a valid 
`root` hash by chance, two amplifying scenarios make this dangerous:

1. **Search space expansion**: Combined with other bugs (e.g., missing nullifier 
   constraint), the prover has more degrees of freedom to find collisions.

2. **Context-dependent escalation**: If any external logic (nullifier derivation, 
   voting power, role assignment) depends on the direction bits, the prover can 
   manipulate it freely. In Tornado-style protocols, this can mean the same leaf 
   produces multiple distinct "positions" → double-spend potential.

**Fix**:
```circom
direction * (1 - direction) === 0;
```

When `direction = 0`: `0 · 1 = 0` ✓
When `direction = 1`: `1 · 0 = 0` ✓
When `direction = 2`: `2 · (-1) = -2 ≠ 0` ✗ → proof rejected.

---

## Lesson

Any signal used as a "boolean" in branchless arithmetic must be explicitly 
constrained to be 0 or 1.

### Mental rule

**Every input that participates in conditional logic needs `x * (1 - x) === 0`. 
No exceptions.**

This pattern recurs everywhere in circuits:
- Direction bits in Merkle proofs
- Vote choices in voting circuits
- "is_admin" flags
- Selector bits in multiplexers
