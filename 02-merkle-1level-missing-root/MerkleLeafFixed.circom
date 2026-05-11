pragma circom 2.0.0;
include "circomlib/poseidon.circom";

// PATCHED VERSION
// The computed Merkle hash is now constrained equal to the expected root.

template MerkleLeaf() {
    signal input leaf;
    signal input sibling;
    signal input root;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== leaf;
    hasher.inputs[1] <== sibling;

    // Fix: constrain the computed hash to equal the expected root
    hasher.out === root;
}

component main {public [root]} = MerkleLeaf();
