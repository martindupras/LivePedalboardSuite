// MagicDisplayGUI_PerfHUD_ActiveOverlay_Ext.scd
// v0.1.1 (robust attach + returns view)
// MD 2025-09-26 15:58 BST

/* Purpose
   A thin ACTIVE overlay bar at the top of the HUD.
   - A = green, B = blue-ish.
   - Robust window lookup (name contains "MagicDisplayGUI" or "PerfHUD").
   - Returns the overlay view (so "-> a UserView" shows in post).
   Style: var-first; descriptive lowercase; AppClock-only; no server.sync.
*/

(
~md_currentChain = ~md_currentChain ? \A;

~md_attachActiveOverlay = {
    var windowsList, hudWindow, nameString, barHeight, overlayView, refreshRoutine;
    windowsList = Window.allWindows;

    hudWindow = windowsList.detect({ arg w;
        var n;
        n = w.tryPerform(\name);
        nameString = n.notNil.if({ n.asString }, { "" });
        (nameString.contains("MagicDisplayGUI") or: { nameString.contains("PerfHUD") })
    });

    if(hudWindow.isNil) {
        "⚠️ No MagicDisplayGUI/PerfHUD window found.".warn;
        ^nil
    };

    barHeight = 8;

    overlayView = UserView(hudWindow, Rect(0, 0, hudWindow.bounds.width, barHeight));
    overlayView.background_(Color.clear);

    overlayView.drawFunc_({ arg v;
        var isA, color;
        isA = (~md_currentChain ? \A) == \A;
        color = isA.if({ Color(0.18, 0.8, 0.18) }, { Color(0.18, 0.45, 0.95) });
        Pen.fillColor = color;
        Pen.addRect(Rect(0, 0, v.bounds.width, v.bounds.height));
        Pen.fill;
    });

    refreshRoutine = Routine({
        var keepRunning;
        keepRunning = true;
        while({ keepRunning and: { hudWindow.notNil and: { hudWindow.isClosed.not } } }, {
            overlayView.bounds = Rect(0, 0, hudWindow.bounds.width, barHeight);
            overlayView.refresh;
            0.20.wait;
        });
    }).play(AppClock);

    ~md_activeOverlayView = overlayView;
    ~md_activeOverlayRoutine = refreshRoutine;

    "[HUD] active overlay attached (top bar)".postln;
    overlayView   // IMPORTANT: return the view (not nil)
};

~md_detachActiveOverlay = {
    var view, routine;
    view = ~md_activeOverlayView; routine = ~md_activeOverlayRoutine;
    if(routine.notNil) { routine.stop };
    if(view.notNil) { view.remove };
    ~md_activeOverlayView = nil; ~md_activeOverlayRoutine = nil;
    "[HUD] active overlay removed".postln;
    nil
};
)
