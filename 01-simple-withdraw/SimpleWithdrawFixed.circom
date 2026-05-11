pragma circom 2.0.0;
include "circomlib/poseidon.circom";
include "circomlib/comparators.circom";

// PATCHED VERSION
// All 4 findings from audit-notes.md addressed:
//   1. Nullifier output constrained with <== (was <--)
//   2. Range check on subtraction prevents field underflow
//   3. Private amount linked to public withdrawAmount
//   4. userBalance bound to commitment (architectural fix)

template SimpleWithdraw() {
    // === PRIVATE INPUTS ===
    signal input secret;
    signal input userBalance;
    signal input amount;

    // === PUBLIC INPUTS ===
    signal input commitmentHash;
    signal input nullifierContext;
    signal input withdrawAmount;

    // === PUBLIC OUTPUTS ===
    signal output nullifier;
    signal output remainingBalance;

    // 1. Verify the user knows the secret AND the balance behind the commitment
    //    (Fix 4: commitment now binds both secret and userBalance)
    component computeCommitment = Poseidon(2);
    computeCommitment.inputs[0] <== secret;
    computeCommitment.inputs[1] <== userBalance;
    computeCommitment.out === commitmentHash;

    // 2. Compute the nullifier and CONSTRAIN it (Fix 1: <== instead of <--)
    component computeNullifier = Poseidon(2);
    computeNullifier.inputs[0] <== secret;
    computeNullifier.inputs[1] <== nullifierContext;
    nullifier <== computeNullifier.out;

    // 3. Range check: amount must not exceed userBalance (Fix 2: prevents underflow)
    component balanceCheck = GreaterEqThan(64);
    balanceCheck.in[0] <== userBalance;
    balanceCheck.in[1] <== amount;
    balanceCheck.out === 1;

    // 4. Subtract safely now that we know amount <= userBalance
    signal newBalance;
    newBalance <== userBalance - amount;
    remainingBalance <== newBalance;

    // 5. Link the private amount to the public withdrawAmount (Fix 3)
    amount === withdrawAmount;
}

component main {public [commitmentHash, nullifierContext, withdrawAmount]} = SimpleWithdraw();
