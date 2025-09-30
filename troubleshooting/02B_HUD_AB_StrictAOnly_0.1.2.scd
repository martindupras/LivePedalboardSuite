//////////////////////////////////////////////////////////////
// 02B_HUD_AB_StrictAOnly.scd
// v0.1.2
// MD 20250929-1120

/* Purpose
 - Force the HUD to show Chain A as ACTIVE with a solid highlight.
 - Optional: stop demo overlays/meters if those extensions are loaded.
Style
 - var-first, AppClock for UI, no server.sync, nil-safe responders.
*/

(
var gui, setSolidA;

gui = ~gui; // provided earlier in your run (01b_StartHere_NoReboot / HUD bring-up)

// do nothing if HUD missing
if(gui.isNil) { "02B_HUD_AB_StrictAOnly: ~gui is nil (skipping).".warn; ^nil; };

setSolidA = {
    // 1) Solid highlight on Chain A (GridDemo API)
    if(gui.respondsTo(\highlightCurrentColumn)) {
        gui.highlightCurrentColumn(\chainA);
    };

    // 2) Optional: stop demo visual drivers if present (extensions)
    if(gui.respondsTo(\testMeter_stop)) { gui.testMeter_stop };
    if(gui.respondsTo(\testMarker_clear)) { gui.testMarker_clear };

    // 3) Small confirmation in the status line
    if(gui.respondsTo(\showExpectation)) {
        gui.showExpectation("HUD: Chain A ACTIVE (solid)", 0);
    };
};

// Schedule on AppClock to be safe for UI operations
AppClock.sched(0.0, { setSolidA.value; nil });
)
