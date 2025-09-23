// Fallback_Acceptance_PassFail.scd
// v0.1.0 — 2025-09-23 16:20 BST (MD)
//
// Purpose
// - Run: /add/delay → /switch → /bypass/delay/on → /bypass/delay/off → /switch
// - After each switch, assert A XOR B and post PASS/FAIL.
// Style
// - var-first everywhere; AppClock scheduling; Server.default.bind for Ndefs; no server.sync.

(
var say, assertXor, ok, mpb, gui, useAdapter;
var ensureSources, applyViaAdapter, applyDirect, applyOne, stepSeries, gap, i, sched;

say = { |msg| ("[ACCEPT] " ++ msg).postln };
assertXor = { |expectA, expectB, label|
    var aPlay, bPlay, okFlag, tag;
    aPlay  = Ndef(\chainA).isPlaying;
    bPlay  = Ndef(\chainB).isPlaying;
    okFlag = (aPlay == expectA) and: { bPlay == expectB };
    tag    = if(okFlag) { "PASS" }{ "FAIL" };
    (tag ++ " — " ++ label ++ " (A=" ++ aPlay ++ " B=" ++ bPlay ++ ")").postln;
};

ok = (~system.notNil) and: { ~system.pedalboard.notNil };
if(ok.not) { say.("⚠️ Bring-up first (Start Option B)."); ^nil; };
mpb = ~system.pedalboard;
gui = ~system.statusDisplay;
useAdapter = (~ct_applyOSCPathToMPB.notNil);

ensureSources = {
    var defined;
    defined = false;
    Server.default.bind({
        var needMelody, needSilent;
        needMelody = Ndef(\testmelody).source.isNil;
        needSilent = Ndef(\ts0).source.isNil;
        if(needMelody) {
            Ndef(\testmelody, {
                var trig, seqd, f, env, pan;
                trig = Impulse.kr(3.2);
                seqd = Dseq([220,277.18,329.63,392,329.63,277.18,246.94], inf);
                f    = Demand.kr(trig, 0, seqd);
                env  = Decay2.kr(trig, 0.01, 0.35);
                pan  = ToggleFF.kr(trig).linlin(0, 1, -0.6, 0.6);
                Pan2.ar(SinOsc.ar(f) * env * 0.25, pan)
            });
        };
        Ndef(\testmelody).ar(2);
        if(needSilent) { Ndef(\ts0, { Silent.ar(2) }) };
        Ndef(\ts0).ar(2);
        Ndef(\chainA).ar(2);
        Ndef(\chainB).ar(2);
    });
    if(mpb.respondsTo(\setSourceCurrent)) { mpb.setSourceCurrent(\testmelody) };
    if(mpb.respondsTo(\enforceExclusiveCurrentOptionA)) { mpb.enforceExclusiveCurrentOptionA(0.1) };
    say.("sources ensured; Option A enforced (if present).");
};

applyViaAdapter = { |path|
    var canShow;
    say.("apply → " ++ path);
    ~ct_applyOSCPathToMPB.(path, mpb, gui);
    canShow = gui.notNil and: { gui.respondsTo(\showExpectation) };
    if(canShow) { gui.showExpectation("Sent: " ++ path, 0) };
};

applyDirect = { |path|
    var segs, verb, key, src, onOff, state;
    segs = path.asString.split($/).reject({ |s| s.size == 0 });
    if(segs.size == 0) { ^nil };
    verb = segs[0].asString;
    say.("direct → " ++ path);
    switch(verb,
        "add", {
            if(segs.size >= 2 and: { mpb.respondsTo(\add) }) {
                key = segs[1].asSymbol; mpb.add(key);
            };
        },
        "setSource", {
            if(segs.size >= 2 and: { mpb.respondsTo(\setSource) }) {
                src = segs[1].asSymbol; mpb.setSource(src);
            };
        },
        "switch", {
            if(mpb.respondsTo(\switchChain)) { mpb.switchChain(0.12) };
        },
        "bypass", {
            if(segs.size >= 3) {
                key   = segs[1].asSymbol;
                onOff = segs[2].asString.toLower;
                state = (onOff == "on") or: { onOff == "true" } or: { onOff == "1" };
                if(mpb.respondsTo(\bypassCurrent)) { mpb.bypassCurrent(key, state) } {
                    if(mpb.respondsTo(\bypass)) { mpb.bypass(key, state) };
                };
            };
        },
        { /* no-op */ }
    );
};

applyOne = { |path| if(useAdapter) { applyViaAdapter.value(path) }{ applyDirect.value(path) } };

stepSeries = [
    { applyOne.value("/add/delay") },
    { applyOne.value("/switch"); assertXor.(false, true,  "after first switch") },
    { applyOne.value("/bypass/delay/on") },
    { applyOne.value("/bypass/delay/off") },
    { applyOne.value("/switch"); assertXor.(true,  false, "after second switch") }
];

gap = 0.60;
i   = 0;

sched = {
    if(i >= stepSeries.size) { say.("done."); ^nil; };
    stepSeries[i].value;
    i = i + 1;
    AppClock.sched(gap, { sched.value; nil });
};

ensureSources.value;
AppClock.sched(0.0, { sched.value; nil });
)
