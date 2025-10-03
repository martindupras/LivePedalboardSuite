// Test_LPS_WindowManager_BringUp.scd
// v0.1.2
// MD 20251003-1138

/* Purpose/Style:
- Acceptance: enforce a single GUI window using the manager, building LPDisplayLayoutWindow.
- Returns '-> a Window'.
*/

(
var createdWindow, windowPrefix, builderFunction, desiredTitle;

("Running: Test_LPS_WindowManager_BringUp.scd").postln;

windowPrefix = "MagicDisplayGUI";
desiredTitle = "MagicDisplayGUI - LPDisplayLayout";

// Builder must return a Window
builderFunction = { |requestedTitle|
    var createdWindowLocal;
    createdWindowLocal = LPDisplayLayoutWindow.respondsTo(\open).if({
        LPDisplayLayoutWindow.open
    }, {
        LPDisplayLayoutWindow.new
    });
    createdWindowLocal.notNil.if({
        createdWindowLocal.name = requestedTitle;
    });
    createdWindowLocal
};

// Bring up exactly one window and front it
createdWindow = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);

// Return -> a Window
createdWindow
)