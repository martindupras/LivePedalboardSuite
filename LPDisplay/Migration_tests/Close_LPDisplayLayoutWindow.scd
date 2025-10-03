// Close_LPDisplayLayoutWindow.scd
// v0.1.0
// MD 20251003-1110

/* Purpose/Style:
- Find and close any open windows whose name matches LPDisplayLayoutWindow (or default).
*/

(
var closedCount;

("Running: Close_LPDisplayLayoutWindow.scd").postln;


closedCount = 0;
Window.allWindows.do({ |w|
    var matches;
    matches = (w.name == "LPDisplayLayoutWindow") or: { w.name.contains("LPDisplayLayoutWindow") };
    matches.if({
        w.close;
        closedCount = closedCount + 1;
    });
});

("Closed LPDisplayLayoutWindow windows: " ++ closedCount.asString).postln;
)