//02B_HUD_AB_StrictAOnly_PerfHUDorGrid.scd
//v0.2.0
//MD 20250929-13:05

/* Purpose
   - Show Chain A as ACTIVE with a solid highlight in the current HUD.
   - Works with either GridDemo controller (~gui respondsTo \highlightCurrentColumn)
     or the PerfHUD window (~gui is a Window) by drawing an overlay.
Style
   - var-first; AppClock-only UI; no server.sync; idempotent; single-window policy.
*/

(
var ensureGui, useGridDemo, usePerfHUD, makeOverlay, drawSolidA, win;

ensureGui = {
    if(~gui.isNil) {
        // Grab whichever MagicDisplayGUI window exists (likely PerfHUD)
        ~gui = Window.allWindows.detect({ |w|
            (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI")
        });
    };
    if(~gui.isNil) { "02B: No MagicDisplayGUI window found.".warn; };
    win = if(~gui.isKindOf(Window)) { ~gui } { ~gui.tryPerform(\window) };
    if(win.notNil) { AppClock.sched(0.00, { win.front.alwaysOnTop_(true); nil }) };
};

useGridDemo = {
    if(~gui.respondsTo(\highlightCurrentColumn)) {
        ~gui.highlightCurrentColumn(\chainA);
        if(~gui.respondsTo(\testMeter_stop)) { ~gui.testMeter_stop };   // stop any demo meter overlay if present
        if(~gui.respondsTo(\testMarker_clear)) { ~gui.testMarker_clear };
        if(~gui.respondsTo(\showExpectation)) { ~gui.showExpectation("HUD: Chain A ACTIVE (solid)", 0) };
        ^true
    };
    ^false
};

// Draws/updates a translucent overlay on left or right half of the window.
makeOverlay = { |w|
    var root, ov, aTint, bTint;
    root = w.tryPerform(\view);
    if(root.isNil) { ^nil };

    ov = w.getProperty(\md_overlay);
    if(ov.isNil) {
        ov = CompositeView(root);
        ov.name_("MD_OVERLAY");
        ov.resize = 5; // eLeft + eTop + eRight + eBottom
        w.setProperty(\md_overlay, ov);
    };

    // two half-width child views: left = A, right = B
    aTint = w.getProperty(\md_overlay_A);
    if(aTint.isNil) {
        aTint = CompositeView(ov); aTint.name_("MD_OVERLAY_A");
        w.setProperty(\md_overlay_A, aTint);
    };
    bTint = w.getProperty(\md_overlay_B);
    if(bTint.isNil) {
        bTint = CompositeView(ov); bTint.name_("MD_OVERLAY_B");
        w.setProperty(\md_overlay_B, bTint);
    };

    // lay out halves
    ov.bounds = root.bounds;
    aTint.bounds = Rect(0, 0, ov.bounds.width/2, ov.bounds.height);
    bTint.bounds = Rect(ov.bounds.width/2, 0, ov.bounds.width/2, ov.bounds.height);

    // gentle green & neutral tints
    aTint.background = Color(0.85, 1.0, 0.85, 0.50);
    bTint.background = Color(0.92, 0.92, 0.92, 0.00); // start hidden
    ov.front;

    // keep overlay aligned on resize
    if(w.onResize.isNil) {
        w.onResize = {
            var rb = root.bounds;
            ov.bounds = rb;
            aTint.bounds = Rect(0, 0, rb.width/2, rb.height);
            bTint.bounds = Rect(rb.width/2, 0, rb.width/2, rb.height);
        };
    };
    ^w
};

drawSolidA = { |w|
    var ov, aTint, bTint;
    ov = w.getProperty(\md_overlay);
    if(ov.isNil) { makeOverlay.(w) };
    aTint = w.getProperty(\md_overlay_A);
    bTint = w.getProperty(\md_overlay_B);
    if(aTint.notNil) { aTint.background = Color(0.85, 1.0, 0.85, 0.50) };
    if(bTint.notNil) { bTint.background = Color(0.92, 0.92, 0.92, 0.00) };
};

AppClock.sched(0.00, {
    ensureGui.value;
    if(~gui.isNil) { ^nil };
    if(useGridDemo.value.not) {
        // PerfHUD path
        if(win.notNil) {
            makeOverlay.(win);
            drawSolidA.(win);
        };
    };
    nil
});
)
