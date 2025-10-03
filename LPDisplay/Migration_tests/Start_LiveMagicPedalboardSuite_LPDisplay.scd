// Start_LiveMagicPedalboardSuite_LPDisplay.scd
// v0.1.3
// MD 20251003-1315

/* Purpose / Style
- (Re)open LPDisplay safely and return -> a Window.
- Always close previous controller (frees OSCdefs & Ndefs).
- Auto-bind LPDisplayAdapter to CommandManager if available.
- Give the window a stable title and define a tiny front helper.
- Style: var-first; AppClock UI only; no server.sync; -> a Window.
*/

(
var ensureServerReady, cleanupPreviousInstance, closeExistingLPDisplayWindows, openLP, autoBindAdapter, win, cm;

ensureServerReady = {
    var s;
    s = Server.default;
    s.waitForBoot({
        s.initTree;
        s.defaultGroup.tryPerform(\freeAll);
    });
    true
};

cleanupPreviousInstance = {
    if(~guiLP.notNil) {
        ~guiLP.close;      // frees LPDisplay OSCdefs & Ndefs; closes its window
        ~guiLP = nil;
        ~lp_window = nil;
        "Closed previous LPDisplay instance (controller + resources).".postln;
    };
    nil
};

closeExistingLPDisplayWindows = {
    Window.allWindows
    .select({ arg w; var n = w.tryPerform(\name);
        n.notNil and: { n.asString.contains("LPDisplay") or: { n.asString.contains("Layout Test") } }
    })
    .do(_.close);
    nil
};

openLP = {
    var inst, winLocal;
    inst = LPDisplayLayoutWindow.new(nil);  // raw 0..1 meters
    winLocal = inst.open;                   // -> a Window
    // give it a stable title so we can front it later (no dependence on old names)
    winLocal.tryPerform(\name_, "LPDisplay — LivePedalboard");
    // publish
    ~guiLP = inst;
    ~lp_window = winLocal;
    // tiny front helper
    ~lp_front = { (~lp_window.notNil).if({ ~lp_window.front.alwaysOnTop_(true) }) };
    "LPDisplay is up. Try ~guiLP.sendPaneText(\\system, \"hello\");".postln;
    winLocal
};

autoBindAdapter = {
    // If LPDisplayAdapter is compiled and ~system.commandManager exists, bind it.
    var adapter;
    adapter = (LPDisplayAdapter.respondsTo(\new) and: { ~guiLP.notNil }).if({
        LPDisplayAdapter.new(~guiLP)
    }, { nil });
    cm = (~system.notNil).if({ ~system.tryPerform(\commandManager) }, { nil });
    if(cm.notNil and: { adapter.notNil }) {
        cm.display = adapter;
        ~lp_adapter = adapter;
        "Adapter bound to CommandManager.".postln;
    }{
        "Note: adapter not bound (no ~system.commandManager yet). You can bind later with LPDisplayAdapter.new(~guiLP).".postln;
    };
    nil
};

// sequence
ensureServerReady.();
cleanupPreviousInstance.();
closeExistingLPDisplayWindows.();
win = openLP.();
autoBindAdapter.();

~lp_front.();   // bring it forward

win  // returning the Window prints '-> a Window'
)