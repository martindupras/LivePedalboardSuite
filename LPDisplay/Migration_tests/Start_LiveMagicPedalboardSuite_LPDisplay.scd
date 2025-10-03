// Start_LiveMagicPedalboardSuite_LPDisplay.scd
// v0.1.5
// MD 20251003-1455

/* Purpose / Style
- (Re)open LPDisplay safely and return -> a Window.
- NON-DESTRUCTIVE to your running audio: no initTree, no defaultGroup.freeAll.
- Still tears down prior LPDisplay instance + its OSC responders (so re-runs are clean).
- Publishes ~guiLP (controller), ~lp_window (Window), ~lp_front helper.
- Style: tilde vars; var-first; lowercase; AppClock UI only; no server.sync.
*/

(
var ensureServerReady, cleanupLPDisplayOnly, openLP, freeOscdefIf;

// ensure server is up, but do NOT clear node tree (we keep your audio alive)
ensureServerReady = {
    var s;
    s = Server.default;
    s.waitForBoot({ "Server is up (non-destructive)".postln; });
    true
};

// free a named OSCdef if it exists
freeOscdefIf = { arg nameSym;
    var d;
    d = OSCdef.all.tryPerform(\at, nameSym);
    (d.notNil).if({ d.free; ("Freed OSCdef: " ++ nameSym.asString).postln; });
    nil
};

// close previous LPDisplay controller and extra responders that belong to it
cleanupLPDisplayOnly = {
    if(~guiLP.notNil) {
        // controller.close should stop its responders; we also belt-and-braces free by name if present
        ~guiLP.close;
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
    var inst, winLocal;
    inst = LPDisplayLayoutWindow.new(nil);   // raw 0..1 meter mapping initially
    winLocal = inst.open;                    // -> a Window
    winLocal.tryPerform(\name_, "LPDisplay — LivePedalboard");
    ~guiLP = inst;
    ~lp_window = winLocal;
    ~lp_front = { (~lp_window.notNil).if({ ~lp_window.front.alwaysOnTop_(true) }) };
    "LPDisplay is up. Try ~guiLP.sendPaneText(\\system, \"hello\");".postln;
    winLocal
};

ensureServerReady.();
cleanupLPDisplayOnly.();
~lp_window = nil;  // close any title-matching windows not required; keep it minimal
~lp_front = nil;

openLP.().front.alwaysOnTop_(true);  // -> a Window
)
