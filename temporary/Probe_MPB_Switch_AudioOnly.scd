// Probe_MPB_Switch_AudioOnly.scd
// v0.1.0
// MD 20251005-1708

/*
Purpose
- Trigger a real "/switch" using the installed queueExportCallback
  and print audio-only facts at +120 ms and +600 ms:
  • Ndef(\chainA/B).isPlaying and .numChannels
  • which source object sits in chainA/B (class names)
  • a pedalboard.printChains (if MPB exposes it)
Style
- var-first; lowercase; no server.sync; AppClock for timing.
*/

(
var cm, pb, fire, dump;

cm = ~system.tryPerform(\commandManager);
pb = ~system.tryPerform(\pedalboard);

dump = { |label = "now"|
    var aPlay, bPlay, aCh, bCh, aSrc, bSrc;
    aPlay = (Ndef(\chainA).notNil and: { Ndef(\chainA).isPlaying });
    bPlay = (Ndef(\chainB).notNil and: { Ndef(\chainB).isPlaying });
    aCh   = (Ndef(\chainA).notNil).if({ Ndef(\chainA).numChannels }, { nil });
    bCh   = (Ndef(\chainB).notNil).if({ Ndef(\chainB).numChannels }, { nil });
    aSrc  = (Ndef(\chainA).notNil).if({ (Ndef(\chainA).source ? nil).class }, { nil });
    bSrc  = (Ndef(\chainB).notNil).if({ (Ndef(\chainB).source ? nil).class }, { nil });

    ("[AudioProbe] " ++ label
      ++ "  chainA: play=" ++ aPlay ++ " ch=" ++ aCh ++ " srcClass=" ++ aSrc
      ++ "  |  chainB: play=" ++ bPlay ++ " ch=" ++ bCh ++ " srcClass=" ++ bSrc).postln;

    if(pb.notNil and: { pb.respondsTo(\printChains) }) {
        "---- pedalboard.printChains ----".postln;
        pb.printChains;
        "--------------------------------".postln;
    };
};

fire = {
    if(cm.notNil and: { cm.queueExportCallback.notNil }) {
        cm.queueExportCallback.value("/switch");  // uses the live bridge
        AppClock.sched(0.120, { dump.("T+120 ms"); nil });
        AppClock.sched(0.600, { dump.("T+600 ms"); nil });
    }{
        "⚠️ No commandManager/queueExportCallback found; cannot fire /switch.".warn;
    };
};

dump.("Before");
fire.();
)