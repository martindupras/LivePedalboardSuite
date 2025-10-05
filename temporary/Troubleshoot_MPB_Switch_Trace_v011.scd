// Troubleshoot_MPB_Switch_Trace_v011.scd
// v0.1.1  (no nodeID usage; safer guards; var-first)
// MD 20251005-1846

/*
Purpose
- Observe what happens around /switch without changing your classes or display.
- Prints snapshots at T0 / T+120 / T+300 / T+600:
  * Ndef(\chainA/B/testmelody): isPlaying, numChannels, bus, fadeTime, source class
  * current side (~md_currentChain)
  * pedalboard.printChains (if available)
- Also arms /n_* server notifications *briefly* around the switch window (0.8 s)
  to see node churn. No nodeID filtering (safer).

Style
- var-first; lowercase; no server.sync; AppClock for timing; defensive checks.
*/

(
var s, cm, pb;
var install, uninstall, snapshot, switchAndTrace;
var armNotifiers, disarmNotifiers, mkDef, stamp;

s  = Server.default;
cm = ~system.tryPerform(\commandManager);
pb = ~system.tryPerform(\pedalboard);

stamp = { |tag|
    var t = Date.getDate.stamp;
    ("[" ++ t ++ "] " ++ tag).postln;
};

// -- OSC notifier helpers (no filtering) --------------------------------
mkDef = { |key, path|
    var def;
    def = OSCdef(key, { |msg, time, addr, port|
        // keep noise low: print only key, path and a compact msg head
        var head = (msg.size > 6).if({ msg.copyRange(0, 5) }, { msg });
        ("[SCN] " ++ path ++ "  " ++ head.asString).postln;
    }, path);
    def
};

armNotifiers = {
    s.notify = true;
    mkDef.(\mpb_tr_go,   '/n_go');
    mkDef.(\mpb_tr_end,  '/n_end');
    mkDef.(\mpb_tr_off,  '/n_off');
    mkDef.(\mpb_tr_on,   '/n_on');
    mkDef.(\mpb_tr_set,  '/n_set');
    mkDef.(\mpb_tr_move, '/n_move');
    mkDef.(\mpb_tr_fail, '/fail');
    "[TRACE011] /n_* notifiers ARMED (temporary)".postln;
};

disarmNotifiers = {
    [\mpb_tr_go, \mpb_tr_end, \mpb_tr_off, \mpb_tr_on, \mpb_tr_set, \mpb_tr_move, \mpb_tr_fail].do { |k|
        var d = OSCdef(k);
        if(d.notNil) { d.free };
    };
    "[TRACE011] /n_* notifiers DISARMED".postln;
};

// -- Info helper ---------------------------------------------------------
snapshot = { |label = "now"|
    var infoFor, a, b, tm, cur;

    infoFor = { |key|
        var nd, exists, playing, ch, bus, fade, srcCls;
        nd      = Ndef(key);
        exists  = nd.notNil;
        playing = exists.if({ nd.isPlaying }, { nil });
        ch      = exists.if({ nd.numChannels }, { nil });
        bus     = exists.if({ nd.bus }, { nil });
        fade    = exists.if({ nd.fadeTime }, { nil });
        srcCls  = exists.if({ (nd.source ? nil).class }, { nil });
        (key: key, exists: exists, isPlaying: playing, numChannels: ch, bus: bus, fadeTime: fade, sourceClass: srcCls)
    };

    a  = infoFor.(\chainA);
    b  = infoFor.(\chainB);
    tm = infoFor.(\testmelody);
    cur = (~md_currentChain ? \A);

    stamp.("[SNAP] " ++ label);
    ("  current=" ++ cur.asString).postln;
    ("  chainA: play=" ++ a[\isPlaying] ++ "  ch=" ++ a[\numChannels]
       ++ "  bus=" ++ a[\bus] ++ "  fade=" ++ a[\fadeTime] ++ "  src=" ++ a[\sourceClass]).postln;
    ("  chainB: play=" ++ b[\isPlaying] ++ "  ch=" ++ b[\numChannels]
       ++ "  bus=" ++ b[\bus] ++ "  fade=" ++ b[\fadeTime] ++ "  src=" ++ b[\sourceClass]).postln;
    ("  testmelody: play=" ++ tm[\isPlaying] ++ "  ch=" ++ tm[\numChannels]).postln;

    if(pb.notNil and: { pb.respondsTo(\printChains) }) {
        "---- pedalboard.printChains ----".postln;
        pb.printChains;
        "--------------------------------".postln;
    };
};

// -- public API ----------------------------------------------------------
install = {
    // nothing persistent to install now; notifiers armed per-run
    "[TRACE011] ready (call ~mpbTrace011_switch.() to run one traced switch).".postln;
};

uninstall = {
    disarmNotifiers.();
    "[TRACE011] uninstalled (any OSCdefs freed).".postln;
};

switchAndTrace = {
    var cmLocal, run;
    cmLocal = ~system.tryPerform(\commandManager);

    if(cmLocal.isNil or: { cmLocal.queueExportCallback.isNil }) {
        "⚠️ No queueExportCallback; cannot trigger /switch.".warn;
        ^nil
    };

    run = {
        snapshot.("T0 (before)");
        armNotifiers.();
        cmLocal.queueExportCallback.value("/switch");
        AppClock.sched(0.12, { snapshot.("T+120 ms"); nil });
        AppClock.sched(0.30, { snapshot.("T+300 ms"); nil });
        AppClock.sched(0.60, { snapshot.("T+600 ms"); disarmNotifiers.(); nil });
    };

    run.();
};

// export handles
~mpbTrace011_install   = install;
~mpbTrace011_uninstall = uninstall;
~mpbTrace011_switch    = switchAndTrace;

// auto-note
install.();
)