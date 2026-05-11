pragma circom 2.0.0;
include "circomlib/poseidon.circom";

// PATCHED VERSION
// direction is now strictly constrained to be 0 or 1.

template MerkleLeafDirection() {
    signal input leaf;
    signal input sibling;
    signal input direction;
    signal input root;

    // Fix: enforce direction ∈ {0, 1}
    direction * (1 - direction) === 0;

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
