// 02B_HUD_AB_StrictAOnly.scd
// v0.1.4
// MD 2025-09-29 13:20 BST

/* Purpose
 - Force the HUD to show Chain A as ACTIVE with a solid (non‑pulsing) highlight.
 - If ~gui is nil, bring up GridDemo and set ~gui first (single window).
Style
 - var-first; AppClock UI; no server.sync; nil-safe responders; idempotent.
*/

(
var ensureGui, applySolidA;

ensureGui = {
    if(~gui.isNil) {
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        ~gui = MagicDisplayGUI_GridDemo.new;
    };
    if(~gui.respondsTo(\window)) { ~gui.window.front.alwaysOnTop_(true) };
};

applySolidA = {
    if(~gui.respondsTo(\highlightCurrentColumn)) {
        ~gui.highlightCurrentColumn(\chainA);
    };
    // Shut off any optional demo overlays if present (nil-safe)
    if(~gui.respondsTo(\testMeter_stop)) { ~gui.testMeter_stop };
    if(~gui.respondsTo(\testMarker_clear)) { ~gui.testMarker_clear };
};

AppClock.sched(0.00, { ensureGui.value; applySolidA.value; nil });
)
