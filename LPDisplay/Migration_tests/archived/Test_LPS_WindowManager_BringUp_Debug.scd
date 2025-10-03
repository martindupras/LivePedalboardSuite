// Test_LPS_WindowManager_BringUp_Debug.scd
// v0.1.1
// MD 20251003-1138

/* Purpose/Style:
- Diagnostic bring-up to confirm counts and return type.
- Returns '-> a Window' when successful.
*/

(
var windowPrefix, desiredTitle, builderFunction, resultWindow, beforeCount, afterCount;

("Running: Test_LPS_WindowManager_BringUp_Debug.scd").postln;

windowPrefix = "MagicDisplayGUI";
desiredTitle = "MagicDisplayGUI - LPDisplayLayout";

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
    ("DBG builder -> " ++ (createdWindowLocal.notNil.if({ createdWindowLocal.class.name.asString }, { "nil" }))).postln;
    createdWindowLocal
};

beforeCount = ~lps_findWindowsByPrefix.(windowPrefix).size;
("DBG before: " ++ beforeCount.asString ++ " window(s) with prefix").postln;

resultWindow = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);

afterCount = ~lps_findWindowsByPrefix.(windowPrefix).size;
("DBG after:  " ++ afterCount.asString ++ " window(s) with prefix").postln;
("DBG result is Window: " ++ (resultWindow.notNil and: { resultWindow.isKindOf(Window) }).asString).postln;

resultWindow.notNil.if({ resultWindow.front; });

// Return -> a Window (or nil)
resultWindow
)