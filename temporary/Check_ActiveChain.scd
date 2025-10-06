// Check_ActiveChain.scd
// v0.1.0
// MD 20251006-1752

/*
Purpose
- Read the currently ACTIVE chain (\A or \B) and make sure LPDisplay highlights it.
Style
- var-first; no server.sync; no non-local returns; harmless if already highlighted.
*/

(
var lps, active, adapter, ok;

lps = ~lps;
if (lps.isNil) {
    "[ActiveCheck] ~lps is nil; run Start_LPS_with_LPDisplay.scd first.".warn;
} {
    active  = lps.pedalboard.tryPerform(\currentKey) ? \A;
    adapter = lps.statusDisplay;
    ok      = adapter.notNil;

    ("[ActiveCheck] ACTIVE = " ++ active.asString).postln;

    if (ok) {
        // Re-apply highlight in the LPDisplay UI (no audio impact)
        adapter.setActiveChainVisual(active);
        "[ActiveCheck] LPDisplay highlight refreshed.".postln;
    } {
        "[ActiveCheck] No adapter bound; highlight not refreshed.".warn;
    };
};
)