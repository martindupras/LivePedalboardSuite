// 99_PerfHUD_MetersNow_v3.scd
// v0.3.0
// MD 2025-09-29 15:05 BST

/* Purpose
 - Make PerfHUD meters move by sanitizing level messages before forwarding:
   • Listen:  /md/levels   and  /md/levels_gui
   • Emit  :  /md/levels_bus   (and mirror to /ampA, /ampB)
 - Sanitizer rules (known-good SC only, no non-existent methods):
   1) Prefer the last 4 floats in 0..1
   2) Else prefer the last 4 floats in dB-ish range [-120..+6], map to 0..1 (floor = -48 dB)
   3) Else drop floats >= 2.0 (IDs/counters), take last 4, clip to 0..1
Style
 - var-first; AppClock-only scheduling; no server.sync; idempotent; nil-safe; conservative logging.
*/

(
var out, freeBridges, startBridges, stopBridges, sanitize4, normDb, lastPost;

// 0) Local OSC sender (language port)
out = NetAddr("127.0.0.1", NetAddr.langPort);

// 1) Clean any previous bridges
freeBridges = {
    if(~md_bridge_levels_v3.notNil) { ~md_bridge_levels_v3.free; ~md_bridge_levels_v3 = nil };
    if(~md_bridge_gui_v3.notNil)    { ~md_bridge_gui_v3.free;    ~md_bridge_gui_v3    = nil };
};

// 2) dB → 0..1 with floor
normDb = { arg dbVal, floorDb = -48.0;
    var x;
    x = (dbVal ? floorDb);
    x = x.clip(floorDb, 0.0);
    // linear from floorDb..0 dB → 0..1
    ((x - floorDb) / (0.0 - floorDb))
};

// 3) Get the **last** 4 usable floats
sanitize4 = { arg floatsIn;
    var f, i, count, res, v, dbCand, last4FromDb, raw, startIndex, endIndex;

    // Defensive copy of floats
    f = (floatsIn ? []).collect(_.asFloat);

    // (A) Prefer the last 4 in 0..1
    res = Array.new;
    i = f.size - 1;
    while({ i >= 0 and: { res.size < 4 } }, {
        v = f.at(i);
        if(v.isNumber and: { (v >= 0.0) and: (v <= 1.0) }) {
            res = res.add(v);
        };
        i = i - 1;
    });
    if(res.size >= 4) {
        res = res.reverse; // we collected backwards
        ^res;
    };

    // (B) Else, try last 4 in dB-ish range [-120..+6] → map to 0..1
    dbCand = Array.new; i = f.size - 1;
    while({ i >= 0 and: { dbCand.size < 4 } }, {
        v = f.at(i);
        if(v.isNumber and: { (v >= -120.0) and: (v <= 6.0) }) {
            dbCand = dbCand.add(v);
        };
        i = i - 1;
    });
    if(dbCand.size >= 4) {
        dbCand = dbCand.reverse;
        last4FromDb = dbCand.collect({ arg x; normDb.(x) });
        ^last4FromDb;
    };

    // (C) Last resort: drop obvious IDs/counters (>= 2.0), take last 4, clip 0..1
    raw = f.select({ arg x; x.isNumber and: { x < 2.0 } });
    if(raw.size >= 4) {
        startIndex = (raw.size - 4).max(0);
        endIndex   = raw.size - 1;
        res = raw.copyRange(startIndex, endIndex).collect({ arg x; x.clip(0.0, 1.0) });
        ^res;
    }{
        // Not enough candidates: pad with zeros
        res = raw.collect({ arg x; x.clip(0.0, 1.0) });
        while({ res.size < 4 }, { res = res.add(0.0) });
        ^res;
    };
};

// 4) Bridges: listen → sanitize → forward
startBridges = {
    var throttle;

    throttle = { arg txt;
        var now = SystemClock.seconds;
        if((now - (lastPost ? 0.0)) > 0.60) { txt.postln; lastPost = now };
    };

    ~md_bridge_levels_v3 = OSCdef(\md_bridge_levels_v3, { |msg|
        var floats, chosen, lA, rA, lB, rB, startIndex, endIndex, rawTail;

        floats = msg.select({ arg x; x.isNumber }).collect(_.asFloat);

        // for visibility, show the numeric tail we saw (up to last 6 floats)
        startIndex = (floats.size - 6).max(0);
        endIndex   = floats.size - 1;
        rawTail = (floats.size > 0).if({
            floats.copyRange(startIndex, endIndex)
        }, { [] });

        chosen = sanitize4.(floats); // [lA,rA,lB,rB] in 0..1
        lA = chosen[0]; rA = chosen[1]; lB = chosen[2]; rB = chosen[3];

        out.sendMsg('/md/levels_bus', lA, rA, lB, rB);
        out.sendMsg('/ampA', 0, lA, rA);
        out.sendMsg('/ampB', 0, lB, rB);

        throttle.value(("99v3: /md/levels tail=" ++ rawTail
            ++ "  → bus A=(" ++ lA.round(0.02) ++ "," ++ rA.round(0.02) ++ ")"
            ++ " B=(" ++ lB.round(0.02) ++ "," ++ rB.round(0.02) ++ ")"));
    }, '/md/levels');

    ~md_bridge_gui_v3 = OSCdef(\md_bridge_gui_v3, { |msg|
        var floats, chosen, lA, rA, lB, rB, startIndex, endIndex, rawTail;

        floats = msg.select({ arg x; x.isNumber }).collect(_.asFloat);
        startIndex = (floats.size - 6).max(0);
        endIndex   = floats.size - 1;
        rawTail = (floats.size > 0).if({
            floats.copyRange(startIndex, endIndex)
        }, { [] });

        chosen = sanitize4.(floats);
        lA = chosen[0]; rA = chosen[1]; lB = chosen[2]; rB = chosen[3];

        out.sendMsg('/md/levels_bus', lA, rA, lB, rB);
        out.sendMsg('/ampA', 0, lA, rA);
        out.sendMsg('/ampB', 0, lB, rB);

        throttle.value(("99v3: /md/levels_gui tail=" ++ rawTail
            ++ "  → bus A=(" ++ lA.round(0.02) ++ "," ++ rA.round(0.02) ++ ")"
            ++ " B=(" ++ lB.round(0.02) ++ "," ++ rB.round(0.02) ++ ")"));
    }, '/md/levels_gui');

    "99v3: BRIDGE active (sanitized → /md/levels_bus + /ampA/B)".postln;
};

stopBridges = {
    if(~md_bridge_levels_v3.notNil) { ~md_bridge_levels_v3.free; ~md_bridge_levels_v3 = nil };
    if(~md_bridge_gui_v3.notNil)    { ~md_bridge_gui_v3.free;    ~md_bridge_gui_v3    = nil };
    "99v3: BRIDGE stopped.".postln;
};

// Run
freeBridges.value;
startBridges.value;
)
