// Diag_3_AttachInlineOverlay.scd
// v0.1.0
// MD 2025-09-26 16:55 BST

/* Purpose / Style
   Purpose: Attach a small overlay view inside the existing MagicDisplayGUI window that visualises
            /md/levels (A=2001 bottom half; B=2002 top half). Uses the sniffer’s dictionary.
   Style:   var-first; descriptive lowercase variable names; AppClock; no server.sync.
*/

(
var hudWindow, overlayView, leftPadPixels, viewWidthPixels, viewHeightPixels, refreshRoutine;

hudWindow = Window.allWindows.detect({ arg winRef;
    var titleString;
    titleString = winRef.tryPerform(\name);
    titleString.notNil and: { titleString.asString.beginsWith("MagicDisplayGUI") }
});

if(hudWindow.isNil) { "⚠️ MDSTEP3: No MagicDisplayGUI window; run your bring-up.".warn; ^nil };

leftPadPixels    = 8;
viewWidthPixels  = 22;
viewHeightPixels = 86;

overlayView = UserView(hudWindow, Rect(leftPadPixels, leftPadPixels, viewWidthPixels, viewHeightPixels));
overlayView.background_(Color.clear);

overlayView.drawFunc_({ arg viewRef;
    var valuesA, valuesB, aLeft, aRight, bLeft, bRight, halfHeight, halfWidth;
    valuesA = ~md_levelsById.at(2001) ? [0, 0];
    valuesB = ~md_levelsById.at(2002) ? [0, 0];

    aLeft  = valuesA[0]; aRight = valuesA[1];
    bLeft  = valuesB[0]; bRight = valuesB[1];

    halfHeight = viewRef.bounds.height / 2;
    halfWidth  = viewRef.bounds.width  / 2;

    // A (bottom half) — green left, blue right
    Pen.fillColor = Color(0.35, 0.9, 0.35);
    Pen.addRect(Rect(0,        halfHeight - (halfHeight * aLeft),  halfWidth, halfHeight * aLeft));  Pen.fill;
    Pen.fillColor = Color(0.35, 0.6, 0.95);
    Pen.addRect(Rect(halfWidth, halfHeight - (halfHeight * aRight), halfWidth, halfHeight * aRight)); Pen.fill;

    // B (top half) — subtle tint
    Pen.fillColor = Color(0.35, 0.9, 0.35).blend(Color.white, 0.15);
    Pen.addRect(Rect(0,        viewRef.bounds.height - (halfHeight * bLeft),  halfWidth, halfHeight * bLeft));  Pen.fill;
    Pen.fillColor = Color(0.35, 0.6, 0.95).blend(Color.white, 0.15);
    Pen.addRect(Rect(halfWidth, viewRef.bounds.height - (halfHeight * bRight), halfWidth, halfHeight * bRight)); Pen.fill;
});

// refresh on AppClock
refreshRoutine = Routine({
    var keepRunning;
    keepRunning = true;
    while({ keepRunning and: { hudWindow.notNil and: { hudWindow.isClosed.not } } }, {
        overlayView.refresh;
        0.15.wait;
    });
}).play(AppClock);

"MDSTEP3: inline overlay attached (top-left)".postln;
overlayView
)
