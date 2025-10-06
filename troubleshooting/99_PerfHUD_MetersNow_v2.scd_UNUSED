// 99_PerfHUD_MetersNow_v2.scd
// v0.2.1
// MD 2025-09-29 14:55 BST

/* Purpose
 - Make PerfHUD meters MOVE by bridging your real level messages to the paths PerfHUD reads,
   after SANITIZING payloads (strip bus IDs / counters; normalize to 0..1).
 - Listens on: /md/levels AND /md/levels_gui
 - Emits to : /md/levels_bus  (and mirrors to /ampA, /ampB)
Style
 - var-first; AppClock-only; no server.sync; idempotent; nil-safe; verbose console for verification.
*/

(
var out, freeAll, startBridge, stopBridge, extract4, normDb, lastPost;

// 0) Local OSC sender (language port)
out = NetAddr("127.0.0.1", NetAddr.langPort);

// 1) Clean previous bridges
freeAll = {
    if(~md_bridge_levels_v2.notNil) { ~md_bridge_levels_v2.free; ~md_bridge_levels_v2 = nil };
    if(~md_bridge_gui_v2.notNil)    { ~md_bridge_gui_v2.free;    ~md_bridge_gui_v2    = nil };
};

// 2) dB → 0..1 using a floor (default -48 dB mapped to 0)
normDb = { arg dbVal, floorDb = -48.0;
    var x = dbVal ? floorDb;
    x = x.clip(floorDb, 0.0);
    ^((x - floorDb) / (0.0 - floorDb))  // 0..1
};

// 3) Extract the last 4 meaningful floats [lA,rA,lB,rB] from a float list.
//    - Prefer values already in 0..1
//    - Else accept dB-ish (-120..+6) and convert via normDb
//    - Ignore obvious bus IDs / counters (>= 2.0 and not dB-range)
extract4 = { arg floatsIn;
    var f, tail4, useDb, vA1, vA2, vB1, vB2, floats01, floatsDbRange;

    f = (floatsIn ? []).collect(_.asFloat);

    // 3a) Try to find a **last** window of 4 floats already within 0..1
    floats01 = f.select({ |x| x.isNumber and: { (x >= 0.0) and: (x <= 1.0) } });
    if(floats01.size >= 4) {
        tail4 = floats01.keepLast(4);
        ^tail4; // already 0..1
    };

    // 3b) Else try dB-like values (e.g., -48..0 or up to +6)
    floatsDbRange = f.select({ |x| x.isNumber and: { (x >= -120.0) and: (x <= 6.0) } });
    if(floatsDbRange.size >= 4) {
        tail4 = floatsDbRange.keepLast(4);
        vA1 = normDb.(tail4[0]); vA2 = normDb.(tail4[1]);
        vB1 = normDb.(tail4[2]); vB2 = normDb.(tail4[3]);
        ^[vA1, vA2, vB1, vB2];
    };

    // 3c) Last resort: take **any** floats, drop obviously huge values (>= 2.0),
    //     then if still not enough, pad with zeros.
    tail4 = f.reject({ |x| x >= 2.0 }).keepLast(4);
    tail4 = (tail4 ++ Array.fill((4 - tail4.size).max(0), { 0.0 })).keepLast(4);
    // clip to 0..1 to be safe
    ^tail4.collect({ |x| x.clip(0.0, 1.0) });
};

// 4) Start the sanitizing bridge
startBridge = {
    var postThrottle;

    postThrottle = { arg txt;
        var now = SystemClock.seconds;
        if((now - (lastPost ? 0.0)) > 0.5) { txt.postln; lastPost = now };
    };

    ~md_bridge_levels_v2 = OSCdef(\md_bridge_levels_v2, { |msg|
        var floats, chosen, lA, rA, lB, rB;
        floats = msg.select({ |x| x.isNumber }).collect(_.asFloat);

        chosen = extract4.(floats);  // [lA,rA,lB,rB] normalized 0..1
        lA = chosen[0]; rA = chosen[1]; lB = chosen[2]; rB = chosen[3];

        // Emit to PerfHUD-friendly paths
        out.sendMsg('/md/levels_bus', lA, rA, lB, rB);
        out.sendMsg('/ampA', 0, lA, rA);
        out.sendMsg('/ampB', 0, lB, rB);

        postThrottle.value("99v2: /md/levels → levels_bus A=("
            ++ lA.round(0.01) ++ "," ++ rA.round(0.01) ++ ")  B=("
            ++ lB.round(0.01) ++ "," ++ rB.round(0.01) ++ ")");
    }, '/md/levels');

    ~md_bridge_gui_v2 = OSCdef(\md_bridge_gui_v2, { |msg|
        var floats, chosen, lA, rA, lB, rB;
        floats = msg.select({ |x| x.isNumber }).collect(_.asFloat);

        chosen = extract4.(floats);
        lA = chosen[0]; rA = chosen[1]; lB = chosen[2]; rB = chosen[3];

        out.sendMsg('/md/levels_bus', lA, rA, lB, rB);
        out.sendMsg('/ampA', 0, lA, rA);
        out.sendMsg('/ampB', 0, lB, rB);

        postThrottle.value("99v2: /md/levels_gui → levels_bus A=("
            ++ lA.round(0.01) ++ "," ++ rA.round(0.01) ++ ")  B=("
            ++ lB.round(0.01) ++ "," ++ rB.round(0.01) ++ ")");
    }, '/md/levels_gui');

    "99v2: BRIDGE active (sanitized → levels_bus + ampA/B)".postln;
};

stopBridge = {
    if(~md_bridge_levels_v2.notNil) { ~md_bridge_levels_v2.free; ~md_bridge_levels_v2 = nil };
    if(~md_bridge_gui_v2.notNil)    { ~md_bridge_gui_v2.free;    ~md_bridge_gui_v2    = nil };
    "99v2: BRIDGE stopped.".postln;
};

// Run
freeAll.value;
startBridge.value;
)
