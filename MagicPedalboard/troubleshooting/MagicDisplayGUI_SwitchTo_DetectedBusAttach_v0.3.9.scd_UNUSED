// MagicDisplayGUI_SwitchTo_DetectedBusAttach_v0.3.9.scd
// v0.3.9
// MD timestamp: 2025-09-25

/* Purpose
   - Auto-detect Ndef(\chainA/\chainB) audio bus base indices (if present).
   - Ensure routing (bus/groups) exists even after a server reboot.
   - Attach A (2001) and B (2002) probes directly to those busses.
   - Neutralize any prior .filter taps (identity pass-through) and free their private busses.

   Style
   - var-first in every block; no non-local returns (^).
   - descriptive lowercase names; known-good SC syntax.
*/

(
var ok, haveBringUp, detectBusIndex, aIdx, bIdx, neutralizeTap;

ok = true;
haveBringUp = (~md_attachProbesAB.notNil);

if (haveBringUp.not) {
    "Bring-up not loaded. Run MagicDisplayGUI_New_ServerBootAndProbe_v0.3.7.scd first.".postln;
} {
    // ensure routing exists (rebuilds groups/bus/probe if server rebooted)
    ~md_ensureRouting.value;

    detectBusIndex = { |name|
        var proxy, idx, busObj;
        proxy = Ndef(name);
        idx = -1;
        busObj = nil;
        if (proxy.notNil) {
            busObj = proxy.bus;   // valid when the proxy has produced output
            if (busObj.notNil) { idx = busObj.index; };
        };
        idx;
    };

    neutralizeTap = { |name, key|
        var proxy, canFilter;
        proxy = Ndef(name);
        canFilter = false;
        if (proxy.notNil) {
            canFilter = proxy.respondsTo(\filter);
            if (canFilter) {
                // Overwrite any existing tap with identity to stop extra Out.ar
                proxy.filter(key, { |in| in });
            };
        };
    };

    aIdx = detectBusIndex.value(\chainA);
    bIdx = detectBusIndex.value(\chainB);

    ("Detected buses: chainA=" ++ aIdx.asString ++ " chainB=" ++ bIdx.asString).postln;

    // Attach probes directly (skips -1 safely)
    ~md_attachProbesAB.value(busA: aIdx, busB: bIdx);

    // Neutralize taps (works in all versions; no removeFilter needed)
    neutralizeTap.value(\chainA, \mdProbeTapA);
    neutralizeTap.value(\chainB, \mdProbeTapB);

    // Free the private tap busses if they exist
    if (~md_busA.notNil) { ~md_busA.free; ~md_busA = nil; };
    if (~md_busB.notNil) { ~md_busB.free; ~md_busB = nil; };

    "Switched to direct attach on detected buses; taps neutralized and tap busses freed.".postln;
};

ok;
)
