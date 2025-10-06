// Start_LivePedalboardSuite_BringUp_LPDisplay.scd
// v1.0.1
// MD 20251006-1438

/*
Purpose
- From a clean SC restart, bring up LivePedalboardSystem and show LPDisplay (not the old window).
- Keep it minimal and robust; return -> a Window (the LPDisplay GUI window).

Style
- STRICT: var-first; descriptive lowercase names; no single-letter locals; no non-local returns (^).
- No server.sync; use Server.default.waitForBoot, s.initTree, s.defaultGroup.freeAll.
- AppClock only for any GUI timing.

What this does
1) Boot the server into a known state.
2) Close any existing LPDisplay windows.
3) Create the LPDisplayLayoutWindow controller and obtain its GUI Window safely.
4) Instantiate LivePedalboardSystem.
5) (You uncomment exactly one) bind LPDisplay <-> system using your real helper.
6) Bring the LPDisplay window to front and return it.
*/

(
var server, nowStamp, suiteRoot;
var displayController, displayWindow;
var closeExistingLPDisplayWindows, obtainDisplayWindow, findDisplayWindowByName;

// ----- configuration -----
nowStamp   = Date.getDate.stamp;
suiteRoot  = (Platform.userExtensionDir ++ "/LivePedalboardSuite").standardizePath;
server     = Server.default;

// ----- helpers -----
closeExistingLPDisplayWindows = {
    var windows, nameString;
    windows = Window.allWindows ? [];
    windows.do({ arg w;
        nameString = w.name ? "";
        if(nameString.contains("LPDisplay") or: { nameString.contains("Layout") or: { nameString.contains("MagicDisplayGUI") } }) {
            w.close;
        };
    });
    nil
};

findDisplayWindowByName = {
    var windows, nameString, hit;
    windows = Window.allWindows ? [];
    hit = nil;
    windows.do({ arg w;
        nameString = w.name ? "";
        if(nameString.contains("LPDisplay") or: { nameString.contains("Layout") or: { nameString.contains("MagicDisplayGUI") } }) {
            hit = w;
        };
    });
    hit
};

obtainDisplayWindow = { arg controller;
    // Try common controller methods, then fall back to scanning open windows.
    var w;
    w = nil;

    // Some controllers implement .open, .makeWindow or .build returning a Window.
    if(w.isNil and: { controller.respondsTo(\open) })        { w = controller.open };
    if(w.isNil and: { controller.respondsTo(\makeWindow) })  { w = controller.makeWindow };
    if(w.isNil and: { controller.respondsTo(\build) })       { w = controller.build };
    // Some expose the internal Window via a .window accessor.
    if(w.isNil and: { controller.respondsTo(\window) })      { w = controller.window };

    // If still nil or not a Window, search by window title.
    if(w.isNil or: { w.isKindOf(Window).not }) {
        w = findDisplayWindowByName.value;
    };

    w // may still be nil if the controller didn't create a window
};

// ----- 1) server boot -> known state -----
if(server.serverRunning.not) {
    server.waitForBoot({ ("[Start] Server booted @ " ++ nowStamp).postln; });
} {
    "[Start] Server already running; proceeding.".postln;
};
server.initTree;
server.defaultGroup.freeAll;

// ----- 2) close any prior LPDisplay windows -----
closeExistingLPDisplayWindows.value;

// ----- 3) create LPDisplay controller and obtain the GUI Window -----
displayController = LPDisplayLayoutWindow.new;
displayWindow     = obtainDisplayWindow.value(displayController);

// If the controller didn't create a window, try a simple fallback open.
if(displayWindow.isNil) {
    if(displayController.respondsTo(\open)) {
        displayWindow = displayController.open;
    } {
        // As a last resort, look again by name (a deferred GUI build may have occurred).
        0.1.wait; // small GUI settle
        displayWindow = findDisplayWindowByName.value;
    };
}

// If we still have no Window, post a helpful note but keep going (so you can inspect).
if(displayWindow.isNil) {
    "[Start] LPDisplayLayoutWindow did not return a Window; check the controller's API.".postln;
} {
    displayWindow.front;
}

// ----- 4) instantiate the system (MagicPedalboard + MDMiniLogger + CommandTree) -----
~livePedalboardSystem = LivePedalboardSystem.new;

// ----- 5) YOU CHOOSE ONE binding line and UNCOMMENT it (leave the other commented) -----
// A) If you use the system’s autobind helper (file: LivePedalboardSystem-AutoBindLPDisplay.sc):
// ~livePedalboardSystem.autoBindLPDisplay(displayController);

// B) If you use the adapter (file: LPDisplayAdapter_SetController.sc):
// LPDisplayAdapter.setController(displayController);

// (Optional) If you have an auto-meters helper (file: LivePedalboardSystem-AutoMeters.sc):
// ~livePedalboardSystem.enableAutoMeters; // or ~livePedalboardSystem.autoMetersInstall;

// ----- 6) bring front and return -> a Window -----
if(displayWindow.notNil) { displayWindow.front };
displayWindow // -> a Window (or nil with console guidance)
)