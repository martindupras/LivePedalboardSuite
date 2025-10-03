// StartHere_BringUp_MagicDisplayGUI.scd
// v0.1.1
// MD 20251003-1248

/* Purpose/Style:
- Bring up exactly ONE MagicDisplayGUI window using LPDisplayLayoutWindow.
- Applies saved bounds if present; stores ~lps_mainWindow.
- Returns '-> a Window'.
*/

(
var windowPrefix, desiredTitle, builderFunction, createdWindow;

("Running: StartHere_BringUp_MagicDisplayGUI.scd").postln;

// Require helpers to be loaded first (Install file)
(~lps_bringUpSingleWindow.isNil or: { ~lps_applyLastWindowBounds.isNil }).if({
    "ERROR: Window manager helpers are not installed. Run LivePedalboardSystem_WindowManager_Install.scd first.".warn;
    ^nil
});

// Policy + title
windowPrefix = "MagicDisplayGUI";
desiredTitle = "MagicDisplayGUI - LPDisplayLayout";

// Builder: prefer .open, fallback to .new; must return a Window
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

// Create/reuse single window, then apply saved bounds
createdWindow = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);
~lps_applyLastWindowBounds.(createdWindow, windowPrefix);

// Store handle
~lps_mainWindow = createdWindow;

// Return -> a Window
createdWindow
)