// Test_LPS_WindowManager_Cleanup.scd
// v0.1.0
// MD 20251003-1210

/* Purpose/Style:
- Optional helper: closes all windows with the policy prefix, then brings one back.
- Returns '-> a Window' so the IDE prints a Window reference at the end.
*/

(
var windowPrefix, closedCount, builderFunction, reopened;

("Running: Test_LPS_WindowManager_Cleanup.scd").postln;

windowPrefix = "MagicDisplayGUI";

closedCount = ~lps_closeWindowsByPrefix.(windowPrefix);
("Closed " ++ closedCount.asString ++ " window(s) with prefix '" ++ windowPrefix ++ "'").postln;

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

reopened = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, "MagicDisplayGUI - LPDisplayLayout");
reopened
)