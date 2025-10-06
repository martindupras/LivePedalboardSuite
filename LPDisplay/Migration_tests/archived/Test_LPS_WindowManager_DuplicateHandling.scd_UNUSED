// Test_LPS_WindowManager_DuplicateHandling.scd
// v0.1.0
// MD 20251003-1031

/* Purpose/Style:
- Creates a deliberate duplicate, then reruns bring-up to prove consolidation to one window.
- Returns '-> a Window' (the surviving, normalized window).
*/

(
var strayWindow, consolidatedWindow, windowPrefix, builderFunction;

("Running: Test_LPS_WindowManager_DuplicateHandling.scd").postln;

windowPrefix = "MagicDisplayGUI";

// Create a stray duplicate (simulates accidental extra window)
strayWindow = LPDisplayLayoutWindow.respondsTo(\open).if({
    LPDisplayLayoutWindow.open
}, {
    LPDisplayLayoutWindow.new
});
strayWindow.name = "MagicDisplayGUI - TEMP stray";
strayWindow.front;

// Reuse the same builder as the BringUp test
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

// Consolidate to exactly one window
consolidatedWindow = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, "MagicDisplayGUI - LPDisplayLayout");

// Return -> a Window
consolidatedWindow
)