// Troubleshoot_MPB_Switch_Trace.scd
// v0.1.0
// MD 20251005-1828

/*
Purpose
- Observe (not change) what happens around /switch at the audio layer.
- Prints server node notifications for the Ndef synth nodes behind \chainA/\chainB,
  and snapshots of key Ndef facts at T0 / +120 ms / +300 ms / +600 ms:
  * isPlaying, numChannels, nodeID, bus, fadeTime, sourceClass
- Also prints pedalboard.printChains if available.

Style
- var-first; lowercase; no server.sync; AppClock for timing; defensive checks.
*/

(
var s, cm, pb;
var install, uninstall, snapshot, switchAndTrace;
var updateNodeIDs, mkDef, getInfo;

s  = Server.default;
cm = ~system.tryPerform(\commandManager);
pb = ~system.tryPerform(\pedalboard);

// -- helpers -------------------------------------------------------------

updateNodeIDs = {
    var ids;
    ids = Set.new;
    [\chainA, \chainB].do { |k|
        var nd = Ndef(k);
        if(nd.notNil) {
            var id = nd.nodeID; // NodeProxy node ID of current synth
            if(id.isKindOf(Integer)) { ids.add(id) };
        };
    };
    ~trace_nodeIDs = ids; // Set used by OSCdefs to filter logs
};

mkDef = { |name, path|
    OSCdef(name, { |msg, time, addr, port|
        var nodeId;
        nodeId = msg[1];
        if(~trace_nodeIDs.notNil and: { ~trace_nodeIDs.includes(nodeId) }) {
            ("[SCN] " ++ path ++ "  id=" ++ nodeId ++ "  msg=" ++ msg).postln;
        };
    }, path);
};

getInfo = { |key|
    var nd, info;
    nd = Ndef(key);
    info = (
        key: key,
        exists: nd.notNil,
        isPlaying: nd.notNil.if({ nd.isPlaying }, { nil }),
        numChannels: nd.notNil.if({ nd.numChannels }, { nil }),
        nodeID: nd.notNil.if({ nd.nodeID }, { nil }),
        bus: nd.notNil.if({ nd.bus }, { nil }),
        fadeTime: nd.notNil.if({ nd.fadeTime }, { nil }),
        sourceClass: nd.notNil.if({ (nd.source ? nil).class }, { nil })
    );
    info
};

// -- public API ----------------------------------------------------------

install = {
    s.notify = true;  // enable /n_* notifications from scsynth
    updateNodeIDs.();

    mkDef.(\trace_go,   '/n_go');
    mkDef.(\trace_end,  '/n_end');
    mkDef.(\trace_off,  '/n_off');
    mkDef.(\trace_on,   '/n_on');
    mkDef.(\trace_set,  '/n_set');
    mkDef.(\trace_move, '/n_move');
    mkDef.(\trace_fail, '/fail');

    "[TRACE] node notifications armed for chainA/chainB nodeIDs: "
    ++ (~trace_nodeIDs.asArray).postln;
};

snapshot = { |label = "now"|
    var a, b, tm, cur;
    updateNodeIDs.();

    a  = getInfo.(\chainA);
    b  = getInfo.(\chainB);
    tm = getInfo.(\testmelody);
    cur = (~md_currentChain ? \A);

    ("[SNAP] " ++ label).postln;
    ("  current=" ++ cur.asString).postln;
    ("  chainA: play=" ++ a[\isPlaying] ++ "  ch=" ++ a[\numChannels]
       ++ "  node=" ++ a[\nodeID] ++ "  bus=" ++ a[\bus]
       ++ "  fade=" ++ a[\fadeTime] ++ "  src=" ++ a[\sourceClass]).postln;
    ("  chainB: play=" ++ b[\isPlaying] ++ "  ch=" ++ b[\numChannels]
       ++ "  node=" ++ b[\nodeID] ++ "  bus=" ++ b[\bus]
       ++ "  fade=" ++ b[\fadeTime] ++ "  src=" ++ b[\sourceClass]).postln;
    ("  testmelody: play=" ++ tm[\isPlaying] ++ "  ch=" ++ tm[\numChannels]
       ++ "  node=" ++ tm[\nodeID]).postln;

    if(pb.notNil and: { pb.respondsTo(\printChains) }) {
        "---- pedalboard.printChains ----".postln;
        pb.printChains;
        "--------------------------------".postln;
    };
};

switchAndTrace = {
    var cmLocal;
    cmLocal = ~system.tryPerform(\commandManager);
    if(cmLocal.isNil or: { cmLocal.queueExportCallback.isNil }) {
        "⚠️ No queueExportCallback; cannot trigger /switch.".warn;
        ^nil
    };
    snapshot.("T0 (before)");
    cmLocal.queueExportCallback.value("/switch");
    AppClock.sched(0.12, { snapshot.("T+120 ms"); nil });
    AppClock.sched(0.30, { snapshot.("T+300 ms"); nil });
    AppClock.sched(0.60, { snapshot.("T+600 ms"); nil });
    // also refresh IDs early, so subsequent /n_* are caught
    AppClock.sched(0.05, { updateNodeIDs.(); nil });
};

uninstall = {
    [\trace_go, \trace_end, \trace_off, \trace_on, \trace_set, \trace_move, \trace_fail].do { |k|
        var d;
        d = OSCdef(k);
        if(d.notNil) { d.free };
    };
    "[TRACE] node notifications removed.".postln;
};

// export handles
~mpbTrace_install  = install;
~mpbTrace_uninstall = uninstall;
~mpbTrace_snapshot  = snapshot;
~mpbTrace_switch    = switchAndTrace;

// auto-install
install.();
)