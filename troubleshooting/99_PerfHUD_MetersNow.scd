// 99_PerfHUD_MetersNow.scd
// v0.1.0
// MD 2025-09-29 14:40 BST

/* Purpose
 - Make PerfHUD meters MOVE immediately without touching the GUI or audio routing.
 - Step 1 (2s): emit a visible ramp to /md/levels_bus and /ampA/B (proof meters react).
 - Step 2 (continuous): bridge your real /md/levels & /md/levels_gui to /md/levels_bus (+ /ampA/B).
Style
 - var-first; AppClock-only; no server.sync; idempotent; nil-safe.
*/

(
var out, freeAll, startProof, stopProof, startBridge, stopBridge, lastPost;

// 0) local OSC sender (language port)
out = NetAddr("127.0.0.1", NetAddr.langPort);

// 1) Clean up any previous helpers
freeAll = {
    if(~md_bridge_levels.notNil) { ~md_bridge_levels.free; ~md_bridge_levels = nil };
    if(~md_bridge_gui.notNil)    { ~md_bridge_gui.free;    ~md_bridge_gui    = nil };
    if(~md_probe_perf.notNil)    { ~md_probe_perf.free;    ~md_probe_perf    = nil };
    if(~md_proof_task.notNil)    { ~md_proof_task.stop;    ~md_proof_task    = nil };
};

// 2) SHORT PROOF: drive a ramp so you SEE the meters move now
startProof = {
    var t = 0.0, dt = 1/24, secs = 2.0, steps = (secs / dt).round(1);
    var stepCount = 0, ramp;
    ramp = {
        // 0..1 triangle for A, inverse for B (obvious visual motion)
        var a = ( (stepCount % 24) / 24 );
        var b = 1.0 - a;
        out.sendMsg('/md/levels_bus', a, a, b, b);  // [lA, rA, lB, rB]
        out.sendMsg('/ampA', 0, a, a);
        out.sendMsg('/ampB', 0, b, b);
        stepCount = stepCount + 1;
    };
    ~md_proof_task = Task({
        steps.do({
            ramp.value;
            dt.wait;
        });
    }).play(AppClock);
    "99: PROOF running for 2s → watch meters MOVE now…".postln;
};

stopProof = {
    if(~md_proof_task.notNil) { ~md_proof_task.stop; ~md_proof_task = nil };
    "99: PROOF stopped.".postln;
};

// 3) BRIDGE real levels → /md/levels_bus (+ mirror to /ampA/B)
startBridge = {
    var postThrottle;

    postThrottle = { arg txt;
        var now = SystemClock.seconds;
        if((now - (lastPost ? 0.0)) > 0.5) { txt.postln; lastPost = now };
    };

    ~md_bridge_levels = OSCdef(\md_bridge_levels, { |msg|
        var floats, lA, rA, lB, rB;

        floats = msg.select({ |x| x.isNumber }).collect(_.asFloat);

        // heuristics: last 4 floats are [lA,rA,lB,rB]; fallback if fewer
        if(floats.size >= 4) {
            lA = floats.at(floats.size - 4); rA = floats.at(floats.size - 3);
            lB = floats.at(floats.size - 2); rB = floats.at(floats.size - 1);
        }{
            lA = (floats.first ? 0.0); rA = (floats.drop(1).first ? lA);
            lB = lA; rB = rA;
        };

        // forward to paths PerfHUD commonly consumes
        out.sendMsg('/md/levels_bus', lA.clip(0,1), rA.clip(0,1), lB.clip(0,1), rB.clip(0,1));
        out.sendMsg('/ampA', 0, lA.clip(0,1), rA.clip(0,1));
        out.sendMsg('/ampB', 0, lB.clip(0,1), rB.clip(0,1));

        postThrottle.value("99: bridged → levels_bus A=("
            ++ lA.round(0.01) ++ "," ++ rA.round(0.01) ++ ")  B=("
            ++ lB.round(0.01) ++ "," ++ rB.round(0.01) ++ ")");
    }, '/md/levels');

    ~md_bridge_gui = OSCdef(\md_bridge_gui, { |msg|
        var floats, lA, rA, lB, rB;
        floats = msg.select({ |x| x.isNumber }).collect(_.asFloat);
        if(floats.size >= 4) {
            lA = floats.at(floats.size - 4); rA = floats.at(floats.size - 3);
            lB = floats.at(floats.size - 2); rB = floats.at(floats.size - 1);
            out.sendMsg('/md/levels_bus', lA.clip(0,1), rA.clip(0,1), lB.clip(0,1), rB.clip(0,1));
            out.sendMsg('/ampA', 0, lA.clip(0,1), rA.clip(0,1));
            out.sendMsg('/ampB', 0, lB.clip(0,1), rB.clip(0,1));
        };
    }, '/md/levels_gui');

    "99: BRIDGE active (levels → levels_bus + ampA/B).".postln;
};

stopBridge = {
    if(~md_bridge_levels.notNil) { ~md_bridge_levels.free; ~md_bridge_levels = nil };
    if(~md_bridge_gui.notNil)    { ~md_bridge_gui.free;    ~md_bridge_gui    = nil };
    "99: BRIDGE stopped.".postln;
};

// 4) Optional: tiny probe (prints any level/amp paths for 2s)
~md_probe_perf = OSCdef(\md_probe_perf, { |msg|
    var p = msg[0];
    if(p == '/md/levels' or: { p == '/md/levels_gui' } or: { p == '/md/levels_bus' } or: { p == '/ampA' } or: { p == '/ampB' }) {
        ("[probe] " ++ p ++ " size=" ++ msg.size).postln;
    };
}, nil);

// RUN
freeAll.value;
startProof.value;
AppClock.sched(2.05, { stopProof.value; startBridge.value; nil });
)
