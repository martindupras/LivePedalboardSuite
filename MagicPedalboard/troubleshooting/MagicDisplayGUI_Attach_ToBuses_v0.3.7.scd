// MagicDisplayGUI_Attach_ToBuses_v0.3.7.scd
// v0.3.7
// MD timestamp: 2025-09-25

/* Purpose
   - Attach A/B (and optionally Final) probes by BUS INDICES you provide.
   - Leaves the window unchanged; meters switch to A/B once replies arrive.

   Style
   - var-first in every block; no non-local returns (^).
*/

(
var busA, busB, busFinal, ok;

busA = -1;      // TODO: set to your A chain bus index (stereo base index)
busB = -1;      // TODO: set to your B chain bus index (stereo base index)
busFinal = -1;  // optional: set to your final mix bus index

ok = true;

// sanity check
if (~md_attachProbesAB.isNil) {
    "Bring-up not loaded. Run MagicDisplayGUI_New_ServerBootAndProbe_v0.3.7.scd first.".postln;
} {
    if (busA >= 0 or: { busB >= 0 }) {
        ~md_attachProbesAB.value(busA: busA, busB: busB);
        ("Attached A=" ++ busA.asString ++ " B=" ++ busB.asString).postln;
    } {
        "Set busA/busB indices first (both -1 means skip).".postln;
    };

    if (busFinal >= 0) {
        ~md_attachProbeFinal.value(bus: busFinal);
        ("Attached Final=" ++ busFinal.asString).postln;
    } {
        "Final bus not set; skipping.".postln;
    };
};

ok;
)
