// THIS IS NOT WHAT WE WANT. It's using the old GridDemo window, which does not have working meters.

//01b.1_HUD_EnsureGridDemo.scd
//v0.1.0
//MD 20250929-12:42

/* Purpose
   - Enforce MagicDisplayGUI_GridDemo (non-pulsing) and set ~gui to its controller.
   - Close any existing "MagicDisplayGUI..." windows first to keep a single window.
Style
   - var-first; AppClock-only for UI; no server.sync; idempotent.
*/

(
var closeOldWindows, makeGridDemo, frontIt;

closeOldWindows = {
    AppClock.sched(0.00, {
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        nil
    });
};

makeGridDemo = {
    // Create GridDemo controller; its .window is the Qt window
    ~gui = MagicDisplayGUI_GridDemo.new;
    // Optional, visually useful
    if(~gui.respondsTo(\window)) {
        ~gui.window.alwaysOnTop_(true);
    };
};

frontIt = {
    if(~gui.notNil and: { ~gui.respondsTo(\window) }) {
        ~gui.window.front;
    };
    if(~gui.respondsTo(\showExpectation)) {
        ~gui.showExpectation("GridDemo ready (A/B static highlight, no pulsing)", 0);
    };
};

closeOldWindows.value;
AppClock.sched(0.08, { makeGridDemo.value; AppClock.sched(0.04, { frontIt.value; nil }); nil });
)
