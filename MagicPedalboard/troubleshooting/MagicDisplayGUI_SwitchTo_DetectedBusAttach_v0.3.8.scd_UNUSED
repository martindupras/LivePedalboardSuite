// MagicDisplayGUI_SwitchTo_DetectedBusAttach_v0.3.8.scd
// v0.3.8
// MD timestamp: 2025-09-25
/* Purpose
   - Auto-detect Ndef(\chainA/\chainB) audio bus base indices (if playing).
   - Attach A (replyID 2001) and B (replyID 2002) probes directly to those busses.
   - Remove previously-installed .filter taps and free their private busses (if present).
   - Non-invasive: does not change your chain sound.

   Style
   - var-first in every block; no non-local returns (^).
   - descriptive lowercase names; known-good SC syntax.
*/

(
var detectBusIndex, aIdx, bIdx, ok, hadBringUp;

ok = true;
hadBringUp = (~md_attachProbesAB.notNil);

if (hadBringUp.not) {
    "Bring-up not loaded. Run MagicDisplayGUI_New_ServerBootAndProbe_v0.3.7.scd first.".postln;
} {
    detectBusIndex = { |name|
        var proxy, idx, busObj;
        proxy = Ndef(name);
        idx = -1;
        busObj = nil;
        if (proxy.notNil) {
            busObj = proxy.bus; // valid if the proxy has produced output (ideally playing)
            if (busObj.notNil) { idx = busObj.index; };
        };
        idx;
    };

    aIdx = detectBusIndex.value(\chainA);
    bIdx = detectBusIndex.value(\chainB);

    ("Detected buses: chainA=" ++ aIdx.asString ++ " chainB=" ++ bIdx.asString).postln;

    // attach probes directly to A/B buses (even if one is -1, the helper skips it)
    ~md_attachProbesAB.value(busA: aIdx, busB: bIdx);

    // remove taps if they exist (safe if none present)
    if (Ndef(\chainA).notNil) { Ndef(\chainA).removeFilter(\mdProbeTapA); };
    if (Ndef(\chainB).notNil) { Ndef(\chainB).removeFilter(\mdProbeTapB); };

    if (~md_busA.notNil) { ~md_busA.free; ~md_busA = nil; };
    if (~md_busB.notNil) { ~md_busB.free; ~md_busB = nil; };

    "Switched to direct attach on detected buses; taps removed (if present).".postln;
};

ok;
)
