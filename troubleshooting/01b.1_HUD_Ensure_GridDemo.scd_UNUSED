// 01b.1_HUD_Ensure_GridDemo.scd
// v0.1.1
// MD 2025-09-29 13:20 BST

/* Purpose
 - Close any existing MagicDisplayGUI windows (including PerfHUD) and bring up GridDemo
   so highlighting is NON-PULSING.
 - Set ~gui to the GridDemo controller and front the window.
Style
 - var-first; AppClock-only for UI; no server.sync; idempotent.
*/

(
var closeWindows, bringGrid, frontIt;

closeWindows = {
    Window.allWindows
    .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
    .do(_.close);
};

bringGrid = {
    ~gui = MagicDisplayGUI_GridDemo.new;  // controller object (not a Window)
};

frontIt = {
    if(~gui.respondsTo(\window)) {
        ~gui.window.front.alwaysOnTop_(true);
    };
    if(~gui.respondsTo(\highlightCurrentColumn)) {
        ~gui.highlightCurrentColumn(\chainA); // make it obvious we’re on A
    };
};

AppClock.sched(0.00, { closeWindows.value; nil });
AppClock.sched(0.05, { bringGrid.value; AppClock.sched(0.05, { frontIt.value; nil }); nil });
)
