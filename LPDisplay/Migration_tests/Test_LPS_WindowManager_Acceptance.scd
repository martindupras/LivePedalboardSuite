// Test_LPS_WindowManager_Acceptance.scd
// v0.1.1
// MD 20251003-1248

/* Purpose/Style:
- Single end-to-end acceptance for (B) window management:
  1) bring-up single window
  2) create a stray, then consolidate to one via bring-up
  3) front-or-bring-up should front if exists, otherwise create
  4) bounds save/close/reopen/apply
- Returns '-> a Window'.
*/

(
var windowPrefix, desiredTitle, builderFunction, win, stray, testRect;

("Running: Test_LPS_WindowManager_Acceptance.scd").postln;

(~lps_bringUpSingleWindow.isNil or: { ~lps_applyLastWindowBounds.isNil } or: { ~lps_frontOrBringUpByPrefix.isNil }).if({
    "ERROR: Window manager helpers are not installed. Run LivePedalboardSystem_WindowManager_Install.scd first.".warn;
    ^nil
});

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

// 1) bring-up single
win = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);

// 2) create a stray, then consolidate
stray = LPDisplayLayoutWindow.respondsTo(\open).if({ LPDisplayLayoutWindow.open }, { LPDisplayLayoutWindow.new });
stray.name = "MagicDisplayGUI - STRAY";
win = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);

// 3) front-or-bring-up (non-destructive if exists)
win = ~lps_frontOrBringUpByPrefix.(windowPrefix, builderFunction, desiredTitle);

// 4) bounds save/close/reopen/apply
testRect = Rect(160, 180, 700, 420);
win.bounds = testRect;
~lps_saveWindowBounds.(win, windowPrefix);
~lps_closeWindowsByPrefix.(windowPrefix);
win = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);
~lps_applyLastWindowBounds.(win, windowPrefix);

// Return -> a Window
win
)