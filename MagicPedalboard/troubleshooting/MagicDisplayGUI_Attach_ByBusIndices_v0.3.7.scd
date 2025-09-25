// MagicDisplayGUI_Attach_ByBusIndices_v0.3.7.scd
// v0.3.7
// MD timestamp: 2025-09-25

/* Purpose
   - Attach A/B (and optional Final) probes using your stereo BUS INDICES.
   - A uses replyID 2001, B uses 2002, Final uses 2101.

   Style
   - var-first in every block; no non-local returns (^).
*/

(
var busA, busB, busFinal, ok;

busA = -1;      // TODO: set to your A chain stereo bus base index (e.g., 16)
busB = -1;      // TODO: set to your B chain stereo bus base index (e.g., 24)
busFinal = -1;  // optional final mix stereo bus base index (e.g., 32)

ok = true;

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
    };
};

ok;
)
