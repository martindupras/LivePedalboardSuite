// Test_LPS_WindowBounds_Persist.scd
// v0.1.0
// MD 20251003-1125

/* Purpose/Style:
- Proves that window bounds are saved and restored.
- Sets a known Rect, saves, closes, reopens, and checks equality.
- Returns '-> a Window'.
*/

(
var windowPrefix, builderFunction, desiredTitle, firstWindow, secondWindow, testRect, reopenedRect, closedCount, pass;

("Running: Test_LPS_WindowBounds_Persist.scd").postln;

windowPrefix = "MagicDisplayGUI";
desiredTitle = "MagicDisplayGUI - LPDisplayLayout";
testRect = Rect(120, 140, 730, 420);

// Builder
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

// 1) Bring up, apply saved (if any), set testRect, save
firstWindow = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);
firstWindow.bounds = testRect;
~lps_saveWindowBounds.(firstWindow, windowPrefix);

// 2) Close all with prefix
closedCount = ~lps_closeWindowsByPrefix.(windowPrefix);
("Closed " ++ closedCount.asString ++ " window(s)").postln;

// 3) Reopen and apply saved bounds, then check
secondWindow = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);
~lps_applyLastWindowBounds.(secondWindow, windowPrefix);
reopenedRect = secondWindow.bounds;

pass = (reopenedRect.left == testRect.left)
    and: { reopenedRect.top == testRect.top }
    and: { reopenedRect.width == testRect.width }
    and: { reopenedRect.height == testRect.height };

("Bounds persist check: " ++ pass.asString
 ++ " (got " ++ reopenedRect.asString ++ ", expected " ++ testRect.asString ++ ")").postln;

// Return -> a Window
secondWindow
)