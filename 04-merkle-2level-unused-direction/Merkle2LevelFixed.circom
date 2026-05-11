pragma circom 2.0.0;
include "circomlib/poseidon.circom";

// PATCHED VERSION
// Level 1 now applies the same conditional swap pattern as Level 0,
// driven by direction1.

template Merkle2Level() {
    signal input leaf;
    signal input sibling0;
    signal input sibling1;
    signal input direction0;
    signal input direction1;
    signal input root;

    direction0 * (1 - direction0) === 0;
    direction1 * (1 - direction1) === 0;

    // Level 0 — conditional swap with direction0
    signal level0_in0;
    signal level0_in1;
    level0_in0 <== (1 - direction0) * leaf + direction0 * sibling0;
    level0_in1 <== (1 - direction0) * sibling0 + direction0 * leaf;

    component hash0 = Poseidon(2);
    hash0.inputs[0] <== level0_in0;
    hash0.inputs[1] <== level0_in1;

    // Level 1 — Fix: conditional swap with direction1
    signal level1_in0;
    signal level1_in1;
    level1_in0 <== (1 - direction1) * hash0.out + direction1 * sibling1;
    level1_in1 <== (1 - direction1) * sibling1 + direction1 * hash0.out;

    component hash1 = Poseidon(2);
    hash1.inputs[0] <== level1_in0;
    hash1.inputs[1] <== level1_in1;

    hash1.out === root;
}

component main {public [root]} = Merkle2Level();
