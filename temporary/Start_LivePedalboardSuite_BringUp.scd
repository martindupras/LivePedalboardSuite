// Start_LivePedalboardSuite_BringUp.scd
// v0.9.3
// MD 20251004-17:35

/*
Purpose
- One-run bring-up for LivePedalboardSuite:
  - Open/reuse LPDisplayLayoutWindow (single window).
  - Bring up LivePedalboardSystem (server, pedalboard, command system, MIDI).
  - Auto-bind CommandManager -> LPDisplay via LPDisplayAdapter.
  - Ensure audio graph is materialized; default is muted (CURRENT->\ts0).
  - Enable A/B end-of-chain meters after settle.
  - Set top pane titles to "Chain A"/"Chain B" and show src | procs | sink.
  - Auto-refresh ACTIVE/NEXT visual at start and on "/switch" (via AdapterBridge).

Style
- Single block; var-first; tilde (~) interpreter vars; AppClock for UI only.
- No server.sync; non-destructive across re-runs.
- Returns -> a Window.
*/

(
var lps_startMuted, lpResolveClass, lpOpenWindow, silenceLpDemo, silenceLpDemoDeferred,
    buildChainSummary, setTitlesOnce, findPaneLabel, setLabelString,
    setCurrentSource, win, hadSystem, cm, displayObj;

// CONFIG: set to false if you want the arpeggio audible on bring-up
lps_startMuted = false;

// ---------- LPDisplay helpers ----------
lpResolveClass = { \LPDisplayLayoutWindow.asClass ?? { \LPDisplayLayoutTestWindow.asClass } };

lpOpenWindow = {
    var klass, controller, w;
    klass = lpResolveClass.();
    if(klass.isNil) { "No LPDisplay class found.".warn; ^nil };
    controller = ~guiLP ?? { ~guiLP = klass.new(nil) };
    w = Window.allWindows.detect({ |x| (x.tryPerform(\name) ? "").asString == "Layout Test" })
        ?? { controller.open };
    controller.tryPerform(\setSourceA, \srcZ);  // silence LPDisplay demo tails
    controller.tryPerform(\setSourceB, \srcZ);
    w
};

silenceLpDemo = {
    Server.default.bind({
        [\srcA, \srcB, \srcC, \srcZ, \outA, \outB].do({ |name|
            var nd = Ndef(name); if(nd.notNil) { nd.stop };
        });
    });
    "LPDisplay demo sources silenced.".postln;
};

silenceLpDemoDeferred = { AppClock.sched(0.15, { silenceLpDemo.(); nil }) };

findPaneLabel = { |candidatesArray|
    var found = nil;
    var scan;
    scan = { |view|
        view.children.do({ |child|
            if(child.isKindOf(StaticText) and: { candidatesArray.any({ |s| child.string.asString == s.asString }) }) {
                found = child;
            }{
                scan.(child);
            };
        });
    };
    Window.allWindows.do({ |w| if((w.tryPerform(\name) ? "").asString == "Layout Test") { scan.(w.view) } });
    found
};

setLabelString = { |labelObj, str| if(labelObj.notNil) { { labelObj.string_(str.asString) }.defer } };

buildChainSummary = { |which = \A|
    var pb, src, procs, sink, arr;
    pb = ~system.tryPerform(\pedalboard);

    // source
    src = (which == \A).if({
        pb.tryPerform(\sourceA) ?? { pb.tryPerform(\getSourceA) } ?? { pb.tryPerform(\getSource, \A) }
    },{
        pb.tryPerform(\sourceB) ?? { pb.tryPerform(\getSourceB) } ?? { pb.tryPerform(\getSource, \B) }
    });
    if(src.isNil) { src = (which == \A).if({ \testmelody }, { \ts0 }) };

    // processors
    procs = "(none)";
    arr = (which == \A).if({
        pb.tryPerform(\chainA) ?? { pb.tryPerform(\getChainA) } ?? { pb.tryPerform(\getChain, \A) }
    },{
        pb.tryPerform(\chainB) ?? { pb.tryPerform(\getChainB) } ?? { pb.tryPerform(\getChain, \B) }
    });
    if(arr.isKindOf(Array)) {
        var cleaned = arr.reject({ |sym| [\guitar, \destination, \chainA, \chainB].includes(sym.asSymbol) });
        procs = (cleaned.isEmpty).if({ "(none)" }, { cleaned.collect(_.asString).join(" → ") });
    };

    // sink
    sink = (which == \A).if({ "chainA" }, { "chainB" });

    "src: % | procs: % | sink: %".format(src.asString, procs, sink)
};

setTitlesOnce = {
    var labelA, labelB, txtA, txtB;
    labelA = findPaneLabel.(["Top Left Pane", "Chain A", "Chain A ACTIVE", "Chain A NEXT"]);
    labelB = findPaneLabel.(["Top Right Pane", "Chain B", "Chain B ACTIVE", "Chain B NEXT"]);
    txtA = buildChainSummary.(\A);
    txtB = buildChainSummary.(\B);
    setLabelString.(labelA, "Chain A — " ++ txtA);
    setLabelString.(labelB, "Chain B — " ++ txtB);
};

setCurrentSource = { |sym|
    var pb = ~system.tryPerform(\pedalboard);
    if(pb.notNil) {
        if(pb.respondsTo(\setSourceCurrent)) { pb.setSourceCurrent(sym) };
        if(pb.respondsTo(\enforceExclusiveCurrentOptionA)) { pb.enforceExclusiveCurrentOptionA(0.1) };
        if(pb.respondsTo(\playCurrent)) { pb.playCurrent };
    };
};

// ---------- 1) Open/reuse LPDisplay window ----------
win = lpOpenWindow.();
silenceLpDemo.();
silenceLpDemoDeferred.();
"=== LPDisplay window ready ===".postln;

// ---------- 2) Bring up or reuse LivePedalboardSystem ----------
hadSystem = (~system.notNil);
if(hadSystem.not) {
    ~system = LivePedalboardSystem.new(nil);
    ~system.ensureServerReady;
    ~system.bringUpPedalboard;
    ~system.bringUpCommandSystem;
    ~system.autoBindLPDisplayIfPresent;     // BIND FIRST
    ~system.installAdapterBridge;           // THEN bridge (captures display)
    "OK: LivePedalboardSystem up (headless).".postln;
} {
    "Reusing existing ~system (non-destructive).".postln;
    ~system.autoBindLPDisplayIfPresent;     // ensure bound
    ~system.installAdapterBridge;           // refresh capture
};

// Paint ACTIVE/NEXT at startup (defaults to A if unset)
(~system.statusDisplay.tryPerform(\setActiveChainVisual, (~md_currentChain ? \A)));

// ---------- 3) Audio graph then mute-by-default ----------
~system.ensureAudioOn;
if(lps_startMuted) {
    setCurrentSource.(\ts0);
    Server.default.bind({ var nd = Ndef(\testmelody); if(nd.notNil) { nd.stop } });
    "Current set to ts0 (silent). testmelody stopped.".postln;
} {
    setCurrentSource.(\testmelody);
    "Current set to testmelody (audible).".postln;
};

// ---------- 4) Install meters AFTER settle ----------
AppClock.sched(0.25, {
    ~system.enableAutoMeters(18, 0.5);   // slightly longer post-switch settle
    cm = ~system.commandManager;
    cm.updateDisplay;
    setTitlesOnce.();

    displayObj = (cm ? nil).tryPerform(\display);
    [
        \cmClass, (cm ? \nil).class,
        \displayClass, (displayObj ? \nil).class
    ].postln;
    if(~md_log.notNil) { ~md_log.("BRINGUP OK: bound; meters live; titles set; muted=" ++ lps_startMuted) };
    nil
});

// ---------- 5) Return window so you see "-> a Window" ----------
win
)