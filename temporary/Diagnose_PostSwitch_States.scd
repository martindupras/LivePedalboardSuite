// Diagnose_PostSwitch_States.scd
// v0.1.0
// MD 20251005-1028

/*
Purpose
- Wrap CommandManager.queueExportCallback so that whenever "/switch" is sent,
  we print a concise state snapshot twice: at +120 ms and +600 ms relative to
  the moment the adapter applies the switch.
- What we print each time:
  • Ndef(\testmelody).isPlaying
  • Ndef(\chainA).isPlaying, Ndef(\chainB).isPlaying
  • pedalboard.sourceA, pedalboard.sourceB (if available)
  • CURRENT side (~md_currentChain)
Style
- var-first; lowercase names; no non-local returns; no server.sync.
- AppClock for timing; safe .tryPerform everywhere.
*/

(
var cm, pb, oldCb, dumpState, install, uninstall;

// -- helpers (var-first)
dumpState = { |label = "now"|
    var tmPlay, aPlay, bPlay, srcA, srcB, currentSide;
    tmPlay = (Ndef(\testmelody).notNil and: { Ndef(\testmelody).isPlaying });
    aPlay  = (Ndef(\chainA).notNil and: { Ndef(\chainA).isPlaying });
    bPlay  = (Ndef(\chainB).notNil and: { Ndef(\chainB).isPlaying });
    pb = pb ? ~system.tryPerform(\pedalboard);
    srcA = pb.tryPerform(\sourceA);
    srcB = pb.tryPerform(\sourceB);
    currentSide = (~md_currentChain ? \A);

    ("[Diag] " ++ label
      ++ "  testmelody.isPlaying=" ++ tmPlay
      ++ "  chainA.isPlaying=" ++ aPlay
      ++ "  chainB.isPlaying=" ++ bPlay).postln;

    ("[Diag] " ++ label
      ++ "  sourceA=" ++ srcA
      ++ "  sourceB=" ++ srcB
      ++ "  CURRENT=" ++ currentSide).postln;
};

// -- install wrapper
install = {
    cm = ~system.tryPerform(\commandManager) ? ~cm;
    pb = ~system.tryPerform(\pedalboard);

    if(cm.isNil) {
        "⚠️ Diagnose_PostSwitch_States: ~system.commandManager not found.".warn;
        ^this;
    };

    oldCb = cm.queueExportCallback;

    cm.queueExportCallback = { |pathString|
        var p = pathString.asString;
        // 1) Apply original callback first (preserve behavior)
        if(oldCb.notNil) { oldCb.value(pathString) };

        // 2) If it's a switch, schedule two probes
        if(p.beginsWith("/switch")) {
            AppClock.sched(0.120, { dumpState.("T+120 ms"); nil });
            AppClock.sched(0.600, { dumpState.("T+600 ms"); nil });
        };
        nil  // no non-local return
    };

    "[Diag] post-switch probe installed; will print at +120 ms and +600 ms.".postln;
    "[Diag] Run your /switch path now (e.g., Test_LPS_ManualSwitch.scd).".postln;
};

// -- uninstall wrapper (optional)
uninstall = {
    if(cm.notNil) {
        if(oldCb.notNil) { cm.queueExportCallback = oldCb };
        "[Diag] post-switch probe removed; original callback restored.".postln;
    };
    nil
};

// export handles
~diag_postswitch_install = install;
~diag_postswitch_uninstall = uninstall;

// auto-install once
install.();
)