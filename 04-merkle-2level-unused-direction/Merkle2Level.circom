pragma circom 2.0.0;
include "circomlib/poseidon.circom";

// VULNERABLE — DO NOT USE IN PRODUCTION
// 2-level Merkle proof. The leaf has a path of 2 directions, one per level.
// Each level should hash current value with its sibling in the order dictated
// by the direction bit. Bug: direction1 is unused at level 1. See audit-notes.md.

template Merkle2Level() {
    signal input leaf;
    signal input sibling0;
    signal input sibling1;
    signal input direction0;
    signal input direction1;
    signal input root;

    direction0 * (1 - direction0) === 0;
    direction1 * (1 - direction1) === 0;

    // Level 0 — conditional swap with direction0 (correct)
    signal level0_in0;
    signal level0_in1;
    level0_in0 <== (1 - direction0) * leaf + direction0 * sibling0;
    level0_in1 <== (1 - direction0) * sibling0 + direction0 * leaf;

    component hash0 = Poseidon(2);
    hash0.inputs[0] <== level0_in0;
    hash0.inputs[1] <== level0_in1;

    // Level 1 — FIXED order (BUG: direction1 is ignored)
    component hash1 = Poseidon(2);
    hash1.inputs[0] <== hash0.out;
    hash1.inputs[1] <== sibling1;

    hash1.out === root;
}

component main {public [root]} = Merkle2Level();
