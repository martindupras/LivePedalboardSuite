// Test_LPS_Front_Then_BringUp.scd
// v0.1.0
// MD 20251003-1136

/* Purpose/Style:
- First tries to front an existing window; if none, brings one up.
- Returns '-> a Window' in the bring-up path, or '-> a Window' if one existed.
*/

(
var windowPrefix, builderFunction, desiredTitle, win;

("Running: Test_LPS_Front_Then_BringUp.scd").postln;

windowPrefix = "MagicDisplayGUI";
desiredTitle = "MagicDisplayGUI - LPDisplayLayout";

builderFunction = { |requestedTitle|
    var createdWindowLocal;
    createdWindowLocal = LPDisplayLayoutWindow.respondsTo(\open).if({
        LPDisplayLayoutWindow.open
    }, {
        LPDisplayLayoutWindow.new
    });
    createdWindowLocal.name = requestedTitle;
    createdWindowLocal
};

win = ~lps_frontOrBringUpByPrefix.(windowPrefix, builderFunction, desiredTitle);

// Return -> a Window
win
)