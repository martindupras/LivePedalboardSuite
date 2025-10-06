// Hook_Switch_NoXfade_QCallback.scd
// v0.1.0
// MD 20251005-1819

/*
Purpose
- TEMP: Intercept "/switch" at CommandManager.queueExportCallback (no class edits).
- For "/switch":
  1) self-toggle ~md_currentChain (A <-> B),
  2) update LPDisplay ACTIVE/NEXT via CommandManager.display,
  3) map sources: CURRENT -> \testmelody, NEXT -> \ts0,
  4) tiny tick -> mpb.playCurrent,
  5) keep endpoints stereo (Ndef(\chainA/\chainB).ar(2)).
- All other paths pass through to the original callback (display-only adapter chain).
Style
- var-first; lowercase; no server.sync; AppClock for timing; defensive respondsTo.
*/

(
var cm, pb, install, oldCb;

cm = ~system.tryPerform(\commandManager);
pb = ~system.tryPerform(\pedalboard);

install = {
    var hasPrev;

    if(cm.isNil) {
        "⚠️ No ~system.commandManager; cannot install Hook_Switch_NoXfade_QCallback.".warn;
        ^nil
    };

    // preserve original callback once
    hasPrev = (~cm_qecb_prev.notNil);
    if(hasPrev.not) {
        ~cm_qecb_prev = cm.queueExportCallback;
    };

    // install wrapper
    cm.queueExportCallback = { |pathString|
        var p, isSwitch, oldSide, newSide, disp, currentIsA;

        p = pathString.asString;
        isSwitch = p.beginsWith("/switch");

        if(isSwitch.not) {
            if(~cm_qecb_prev.notNil) { ~cm_qecb_prev.value(pathString) };
            ^nil
        };

        // --- simple switch (no MPB crossfade) ---
        oldSide = (~md_currentChain ? \A);
        newSide = (oldSide == \A).if({ \B }, { \A });
        ~md_currentChain = newSide; // self-toggle

        // update LPDisplay ACTIVE/NEXT
        disp = cm.tryPerform(\display);
        if(disp.notNil) { disp.tryPerform(\setActiveChainVisual, newSide) };

        currentIsA = (newSide == \A);

        // map sources: CURRENT->\testmelody, NEXT->\ts0
        if(pb.notNil) {
            if(currentIsA) {
                if(pb.respondsTo(\setSourceA)) { pb.setSourceA(\testmelody) };
                if(pb.respondsTo(\setSourceB)) { pb.setSourceB(\ts0) };
            }{
                if(pb.respondsTo(\setSourceA)) { pb.setSourceA(\ts0) };
                if(pb.respondsTo(\setSourceB)) { pb.setSourceB(\testmelody) };
            };
        };

        // keep endpoints stereo (idempotent), then play current after a tiny tick
        Server.default.bind({
            if(Ndef(\chainA).notNil) { Ndef(\chainA).ar(2) };
            if(Ndef(\chainB).notNil) { Ndef(\chainB).ar(2) };
        });

        AppClock.sched(0.03, {
            if(pb.notNil and: { pb.respondsTo(\playCurrent) }) { pb.playCurrent };
            nil
        });

        ("[NoXfadeQ] toggled " ++ oldSide.asString ++ "→" ++ newSide.asString
          ++ "  (CURRENT->\\testmelody, NEXT->\\ts0)").postln;

        nil  // do not call original for /switch
    };

    "[NoXfadeQ] installed: queueExportCallback wrapped (display-only adapter preserved for other paths).".postln;
};

// run installer now
install.();
)