// Close_LPDisplayLayoutWindow.scd
// v0.1.1
// MD 20251003-1120

/* Purpose/Style:
- Close any windows created by LPDisplayLayoutWindow tests.
- Matches both "Layout Test" and names containing "LPDisplayLayoutWindow".
- Style: var-first, descriptive names, no single-letter locals.
*/

(
var closedCount;

closedCount = 0;

Window.allWindows.do({ |w|
    var windowName;
    windowName = w.name.asString;
    if(windowName == "Layout Test" or: { windowName.contains("LPDisplayLayoutWindow") }) {
        w.close;
        closedCount = closedCount + 1;
    };
});

("Closed LPDisplayLayoutWindow windows: " ++ closedCount).postln;
closedCount
)