// Verify_Baseline_CurrentAudible_NextSilent.scd
// v0.1.0
// MD 20250923-1032

(
/* Purpose
   - Verify that CURRENT’s sink is the audible one and NEXT’s sink is silent (Option A).
   - Posts a clear PASS/FAIL with details.

   Style
   - var-first; lowercase; no server.sync; .scd-safe (no caret).
*/

var systemReady, pedalboardRef;
var currentSinkSymbol, nextSinkSymbol;
var isChainAPlaying, isChainBPlaying;
var currentIsAudible, nextIsSilent;
var summaryText;

// guards
systemReady = ~system.notNil;
if(systemReady.not) {
    "⚠️ ~system is nil. Run Start_LivePedalboardSystem.scd (Option B) first.".postln;
};

// proceed only if ready
if(systemReady) {
    pedalboardRef = ~system.pedalboard;

    // sink symbols at the heads of CURRENT/NEXT
    currentSinkSymbol = pedalboardRef.effectiveCurrent[0];  // \chainA or \chainB
    nextSinkSymbol    = pedalboardRef.effectiveNext[0];     // \chainB or \chainA

    // live flags (do not change any routing)
    isChainAPlaying = Ndef(\chainA).isPlaying;
    isChainBPlaying = Ndef(\chainB).isPlaying;

    // interpret flags relative to CURRENT/NEXT
    currentIsAudible =
        ((currentSinkSymbol == \chainA) and: { isChainAPlaying })
        or: { (currentSinkSymbol == \chainB) and: { isChainBPlaying } };

    nextIsSilent =
        ((nextSinkSymbol == \chainA) and: { isChainAPlaying.not })
        or: { (nextSinkSymbol == \chainB) and: { isChainBPlaying.not } };

    if(currentIsAudible and: { nextIsSilent }) {
        "✅ Baseline OK: CURRENT is audible; NEXT is silent.".postln;
    }{
        summaryText =
            "⚠️ Baseline mismatch — "
            ++ "CURRENT=" ++ currentSinkSymbol.asString
            ++ " NEXT=" ++ nextSinkSymbol.asString
            ++ " | chainA=" ++ isChainAPlaying
            ++ " chainB=" ++ isChainBPlaying;
        summaryText.postln;
    };
};
)
