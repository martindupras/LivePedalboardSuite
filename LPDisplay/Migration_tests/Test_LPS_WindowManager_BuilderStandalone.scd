// Test_LPS_WindowManager_BuilderStandalone.scd
// v0.1.0
// MD 20251003-1125

/* Purpose/Style:
- Call the same builder logic directly and confirm it returns a Window.
- Returns '-> a Window'.
*/

(
var createdWindow, requestedTitle;

("Running: Test_LPS_WindowManager_BuilderStandalone.scd").postln;

requestedTitle = "MagicDisplayGUI - LPDisplayLayout";

createdWindow = LPDisplayLayoutWindow.respondsTo(\open).if({
    LPDisplayLayoutWindow.open
}, {
    LPDisplayLayoutWindow.new
});

createdWindow.notNil.if({
    createdWindow.name = requestedTitle;
    createdWindow.front;
    ("Builder returned: " ++ createdWindow.class.name.asString).postln;
}, {
    "Builder returned: nil".warn;
});

// Return -> a Window (or nil if builder failed)
createdWindow
)