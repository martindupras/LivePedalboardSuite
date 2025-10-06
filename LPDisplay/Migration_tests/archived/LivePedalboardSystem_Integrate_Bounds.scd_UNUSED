// LivePedalboardSystem_Integrate_Bounds.scd
// v0.1.0
// MD 20251003-1125

/* Purpose/Style:
- Minimal integration: apply saved bounds after creation; save on close.
- Returns '-> a Window'.
*/

(
var createdWindow, windowPrefix, builderFunction, desiredTitle;

("Running: LivePedalboardSystem_Integrate_Bounds.scd").postln;

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

// Bring up single window using your existing manager
createdWindow = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);

// Apply saved bounds (if any), then front
~lps_applyLastWindowBounds.(createdWindow, windowPrefix);
createdWindow.front;

// Save bounds when the window closes
createdWindow.onClose = {
    ~lps_saveWindowBounds.(createdWindow, windowPrefix);
};

// Keep a handle
~lps_mainWindow = createdWindow;

// Return -> a Window
createdWindow
)