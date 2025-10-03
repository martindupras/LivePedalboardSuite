// Start_LiveMagicPedalboardSuite_LPDisplay.scd
// v0.1.4
// MD 20251003-1440

/* Purpose / Style
- Safely (re)open LPDisplay; always close the previous controller first.
- Publishes ~guiLP (controller), ~lp_window (Window), ~lp_front (to front the window).
- Style: var-first; tilde vars; lowercase; AppClock UI only; no server.sync; returns -> a Window.
*/

(
var ensureServerReady, cleanupPreviousInstance, closeExistingLPDisplayWindows, openLP, win, defaultServer;

ensureServerReady = {
    defaultServer = Server.default;
    defaultServer.waitForBoot({
        defaultServer.initTree;
        defaultServer.defaultGroup.tryPerform(\freeAll);
    });
    true
};

cleanupPreviousInstance = {
    if(~guiLP.notNil) {
        ~guiLP.close;  // closes window AND frees LPDisplay responders/Ndefs (prevents "second-run silence")
        ~guiLP = nil;
        ~lp_window = nil;
        "Closed previous LPDisplay instance (controller + resources).".postln;
    };
    nil
};

closeExistingLPDisplayWindows = {
    Window.allWindows
    .select({ arg w; var nameString = w.tryPerform(\name);
        nameString.notNil and: { nameString.asString.contains("LPDisplay") or: { nameString.asString.contains("Layout Test") } }
    })
    .do(_.close);
    nil
};

openLP = {
    var controller, windowLocal;
    controller = LPDisplayLayoutWindow.new(nil);  // raw 0..1 meters; HUD map can be set later
    windowLocal = controller.open;                // -> a Window
    windowLocal.tryPerform(\name_, "LPDisplay — LivePedalboard");
    ~guiLP = controller;
    ~lp_window = windowLocal;
    ~lp_front = { (~lp_window.notNil).if({ ~lp_window.front.alwaysOnTop_(true) }) };
    "LPDisplay is up. Try ~guiLP.sendPaneText(\\system, \"hello\");".postln;
    windowLocal
};

ensureServerReady.();
cleanupPreviousInstance.();
closeExistingLPDisplayWindows.();
win = openLP.();
~lp_front.();
win  // -> a Window
)