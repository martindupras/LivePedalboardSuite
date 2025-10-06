// LivePedalboardSystem_Integrate_WindowManagement.scd
// v0.1.1
// MD 20251003-1031

/* Purpose/Style:
- Minimal integration call for use inside LivePedalboardSystem bring-up.
- Ensures exactly one display window is present, with policy-compliant title.
- Returns '-> a Window'.
*/

(
var createdWindow, windowPrefix, builderFunction, desiredTitle;

("Running: LivePedalboardSystem_Integrate_WindowManagement.scd").postln;

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

createdWindow = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);
~lps_mainWindow = createdWindow;

// Return -> a Window
createdWindow
)