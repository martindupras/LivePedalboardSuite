// Test_LPS_WindowManager_CloseAll.scd
// v0.1.0
// MD 20251003-1031

/* Purpose/Style:
- Closes all windows whose name begins with the policy prefix.
- Returns '-> a Window' by reopening a single window after close.
*/

(
var closedCount, reopenedWindow, windowPrefix, builderFunction;

("Running: Test_LPS_WindowManager_CloseAll.scd").postln;

windowPrefix = "MagicDisplayGUI";

// Close all with the prefix
closedCount = ~lps_closeWindowsByPrefix.(windowPrefix);
("Closed " ++ closedCount.asString ++ " window(s) with prefix '" ++ windowPrefix ++ "'").postln;

// Builder to bring a fresh single window back up
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

// Reopen single window and return it
reopenedWindow = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, "MagicDisplayGUI - LPDisplayLayout");
reopenedWindow
)
