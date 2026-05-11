pragma circom 2.0.0;
include "circomlib/poseidon.circom";

// VULNERABLE — DO NOT USE IN PRODUCTION
// Verifies that `leaf` is in a 2-leaf Merkle tree,
// assuming leaf is the LEFT child and sibling is on the right.
// See audit-notes.md.

template MerkleLeaf() {
    signal input leaf;       // private
    signal input sibling;    // private
    signal input root;       // public — the expected root

    component hasher = Poseidon(2);
    hasher.inputs[0] <== leaf;
    hasher.inputs[1] <== sibling;
}

component main {public [root]} = MerkleLeaf();
