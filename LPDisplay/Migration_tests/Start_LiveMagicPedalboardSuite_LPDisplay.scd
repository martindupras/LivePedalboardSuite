// Start_LiveMagicPedalboardSuite_LPDisplay.scd
// v0.1.6
// MD 20251003-1530

/* Purpose / Style
- (Re)open LPDisplay safely and return -> a Window.
- NON-DESTRUCTIVE to your running audio (no initTree, no defaultGroup.freeAll).
- Teardown only LPDisplay's controller + OSC responders between runs.
- Auto-bind LPDisplayAdapter to SYSTEM CommandManager *if ~system already exists*.
- Publishes ~guiLP (controller), ~lp_window (Window), ~lp_front helper.
- Style: tilde vars; var-first; lowercase; AppClock UI only; no server.sync.
*/

(
var ensureServerReady, freeOscdefIf, cleanupLPDisplayOnly, openLP, autoBindIfSystemExists, defaultServer, windowLocal;

ensureServerReady = {
    defaultServer = Server.default;
    defaultServer.waitForBoot({ "Server is up (non-destructive)".postln; });
    true
};

freeOscdefIf = { arg nameSymbol;
    var oscDef;
    oscDef = OSCdef.all.tryPerform(\at, nameSymbol);
    (oscDef.notNil).if({
        oscDef.free;
        ("Freed OSCdef: " ++ nameSymbol.asString).postln;
    });
    nil
};

cleanupLPDisplayOnly = {
    if(~guiLP.notNil) {
        ~guiLP.close;  // closes window and stops LPDisplay-owned responders/JIT state
        // belt-and-braces: free known OSCdef names if the controller exposes them
        [ ~guiLP.tryPerform(\oscNameA)
        , ~guiLP.tryPerform(\oscNameB)
        , ~guiLP.tryPerform(\oscConsoleA)
        , ~guiLP.tryPerform(\oscConsoleB)
        ].do({ arg sym; (sym.notNil).if({ freeOscdefIf.(sym) }) });
        ~guiLP = nil;
        ~lp_window = nil;
        "Closed previous LPDisplay instance (controller + responders).".postln;
    };
    nil
};

openLP = {
    var controller, win;
    controller = LPDisplayLayoutWindow.new(nil);   // start with raw 0..1 meters
    win = controller.open;                         // -> a Window
    win.tryPerform(\name_, "LPDisplay — LivePedalboard");
    ~guiLP = controller;
    ~lp_window = win;
    ~lp_front = { (~lp_window.notNil).if({ ~lp_window.front.alwaysOnTop_(true) }) };
    "LPDisplay is up. Try ~guiLP.sendPaneText(\\system, \"hello\");".postln;

    // optional: persist a log line if logger is installed
    (~md_log.notNil).if({ ~md_log.("LPDisplay bring-up v0.1.6") });

    win
};

autoBindIfSystemExists = {
    var cm, selectors, sel, adapter;
    // only bind if ~system already exists and exposes a CM under common names
    if(~system.notNil and: { LPDisplayAdapter.respondsTo(\new) }) {
        selectors = [\commandManager, \cmdManager, \cm, \manager];
        sel = selectors.detect({ arg s; ~system.respondsTo(s) and: { ~system.perform(s).notNil } });
        if(sel.notNil) {
            cm = ~system.perform(sel);
            adapter = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(~guiLP) });
            ~lp_adapter = adapter;
            cm.display = adapter;
            cm.updateDisplay;
            "Adapter bound to SYSTEM CommandManager.".postln;
            (~md_log.notNil).if({ ~md_log.("Auto-bound LPDisplayAdapter to SYSTEM CM via selector " ++ sel.asString) });
        };
    };
    nil
};

ensureServerReady.();
cleanupLPDisplayOnly.();

windowLocal = openLP.();
autoBindIfSystemExists.();

windowLocal.front.alwaysOnTop_(true);
windowLocal   // -> a Window
)