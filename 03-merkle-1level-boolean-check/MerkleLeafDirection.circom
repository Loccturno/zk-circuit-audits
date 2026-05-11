pragma circom 2.0.0;
include "circomlib/poseidon.circom";

// VULNERABLE — DO NOT USE IN PRODUCTION
// 1-level Merkle proof with a direction bit. The bit determines whether
// the leaf is the left or right child. Conditional swap is done via
// branchless arithmetic. See audit-notes.md.

template MerkleLeafDirection() {
    signal input leaf;       // private
    signal input sibling;    // private
    signal input direction;  // private — 0 = leaf on left, 1 = leaf on right
    signal input root;       // public

    // Branchless swap (works correctly ONLY if direction ∈ {0,1})
    signal in0;
    signal in1;
    in0 <== (1 - direction) * leaf + direction * sibling;
    in1 <== (1 - direction) * sibling + direction * leaf;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== in0;
    hasher.inputs[1] <== in1;

    hasher.out === root;
}

component main {public [root]} = MerkleLeafDirection();
