// Start_LivePedalboardSuite_BringUp_LPDisplay.scd
// v1.0.2
// MD 20251006-1502

/*
Purpose
- From a clean SC restart, bring up LivePedalboardSystem and show LPDisplay (not the old window).
- Minimal, explicit diagnostics, and returns -> a Window (the LPDisplay GUI window).

Style
- STRICT: var-first; descriptive lowercase names; no single-letter locals; no non-local returns (^).
- No server.sync; use Server.default.waitForBoot, s.initTree, s.defaultGroup.freeAll.
*/

(
var nowStamp, suiteRoot;
var displayController, displayWindow;
var s, postStep, scanForDisplayWindow, closeExistingDisplayWindows;

nowStamp  = Date.getDate.stamp;
suiteRoot = (Platform.userExtensionDir ++ "/LivePedalboardSuite").standardizePath;
s         = Server.default;

postStep = { arg msg; ("[Start-LPDisplay] " ++ msg).postln };

scanForDisplayWindow = {
    var hit;
    hit = nil;
    Window.allWindows.do({ arg w;
        var nameString = w.name ? "";
        if(
            nameString.contains("LPDisplay")
            or: { nameString.contains("Layout") }
            or: { nameString.contains("MagicDisplayGUI") }
        ) {
            hit = w;
        };
    });
    hit
};

closeExistingDisplayWindows = {
    var closedCount;
    closedCount = 0;
    Window.allWindows.do({ arg w;
        var nameString = w.name ? "";
        if(
            nameString.contains("LPDisplay")
            or: { nameString.contains("Layout") }
            or: { nameString.contains("MagicDisplayGUI") }
        ) {
            closedCount = closedCount + 1;
            w.close;
        };
    });
    postStep.value("Closed " ++ closedCount ++ " existing LPDisplay-related window(s).");
    nil
};

// 1) Boot server -> known state
s.serverRunning.not.if({
    postStep.value("Booting server...");
    s.waitForBoot({ postStep.value("Server booted @ " ++ nowStamp) });
},{
    postStep.value("Server already running; proceeding.");
});
s.initTree;
s.defaultGroup.freeAll;
postStep.value("Server tree initialized and default group cleared.");

// 2) Close any existing LPDisplay windows
closeExistingDisplayWindows.value;

// 3) Create LPDisplay controller and obtain its Window safely
postStep.value("Creating LPDisplayLayoutWindow controller...");
displayController = LPDisplayLayoutWindow.new;
postStep.value("Controller created: " ++ displayController.class.asString);

displayWindow = nil;

// Try common controller APIs in order; post diagnostics for each attempt
(displayWindow.isNil and: { displayController.respondsTo(\open) }).if({
    postStep.value("Calling controller.open ...");
    displayWindow = displayController.open;
    postStep.value("controller.open returned: " ++ displayWindow.class.asString);
},{});

(displayWindow.isNil and: { displayController.respondsTo(\makeWindow) }).if({
    postStep.value("Calling controller.makeWindow ...");
    displayWindow = displayController.makeWindow;
    postStep.value("controller.makeWindow returned: " ++ (displayWindow.notNil.if({ displayWindow.class.asString }, { "nil" })));
},{});

(displayWindow.isNil and: { displayController.respondsTo(\build) }).if({
    postStep.value("Calling controller.build ...");
    displayWindow = displayController.build;
    postStep.value("controller.build returned: " ++ (displayWindow.notNil.if({ displayWindow.class.asString }, { "nil" })));
},{});

(displayWindow.isNil and: { displayController.respondsTo(\window) }).if({
    postStep.value("Reading controller.window ...");
    displayWindow = displayController.window;
    postStep.value("controller.window is: " ++ (displayWindow.notNil.if({ displayWindow.class.asString }, { "nil" })));
},{});

// Fallback: scan open windows by title
displayWindow.isNil.if({
    postStep.value("Scanning open windows by name as fallback...");
    displayWindow = scanForDisplayWindow.value;
    postStep.value("Scan result: " ++ (displayWindow.notNil.if({ "found a Window" }, { "no Window found" })));
},{});

// 4) Instantiate the system (MagicPedalboard + MDMiniLogger + CommandTree)
postStep.value("Instantiating LivePedalboardSystem...");
~livePedalboardSystem = LivePedalboardSystem.new;
postStep.value("LivePedalboardSystem instance: " ++ ~livePedalboardSystem.class.asString);

// 5) Bind LPDisplay <-> system (UNCOMMENT EXACTLY ONE LINE YOU USE)
// A) If you use the system’s autobind helper:
// ~livePedalboardSystem.autoBindLPDisplay(displayController); postStep.value("autoBindLPDisplay called.");

// B) If you use the adapter:
// LPDisplayAdapter.setController(displayController); postStep.value("LPDisplayAdapter.setController called.");

// Optional: Auto-meters helper (uncomment if you want it in the starter):
// ~livePedalboardSystem.enableAutoMeters; postStep.value("enableAutoMeters called.");

// 6) Bring to front (only call .front on actual Window)
(displayWindow.notNil).if({
    postStep.value("Bringing LPDisplay window to front...");
    displayWindow.front;
    postStep.value("LPDisplay Window fronted. Starter returning -> a Window.");
},{
    postStep.value("WARNING: Could not obtain an LPDisplay Window. Check controller API and binding step.");
});

displayWindow // -> a Window, or nil with diagnostics above
)