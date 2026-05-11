pragma circom 2.0.0;
include "circomlib/poseidon.circom";

// VULNERABLE — DO NOT USE IN PRODUCTION
// Privacy pool withdrawal circuit. Contains 4 distinct bugs.
// See audit-notes.md for findings.

template SimpleWithdraw() {
    // === PRIVATE INPUTS ===
    signal input secret;          // user's secret
    signal input userBalance;     // user's balance in the pool
    signal input amount;          // amount to withdraw

    // === PUBLIC INPUTS ===
    signal input commitmentHash;     // registered on-chain commitment
    signal input nullifierContext;   // domain separator, e.g. "withdraw_round_5"
    signal input withdrawAmount;     // amount the on-chain contract will pay

    // === PUBLIC OUTPUTS ===
    signal output nullifier;
    signal output remainingBalance;

    // 1. Verify the user knows the secret behind the commitment
    component computeCommitment = Poseidon(1);
    computeCommitment.inputs[0] <== secret;
    computeCommitment.out === commitmentHash;

    // 2. Compute the nullifier (secret + context, to prevent cross-app tracking)
    component computeNullifier = Poseidon(2);
    computeNullifier.inputs[0] <== secret;
    computeNullifier.inputs[1] <== nullifierContext;
    nullifier <-- computeNullifier.out;

    // 3. Compute the new balance after withdrawal
    signal newBalance;
    newBalance <== userBalance - amount;
    remainingBalance <== newBalance;
}

component main {public [commitmentHash, nullifierContext, withdrawAmount]} = SimpleWithdraw();
