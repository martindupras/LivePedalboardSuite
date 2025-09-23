// Fallback_Acceptance_PassFail_Delayed.scd
// v0.1.3
// MD 20250923-1534


/*
Purpose
- Run: /add/delay → /switch → /bypass/delay/on → /bypass/delay/off → /switch
- Verify A XOR B only AFTER crossfade settles (avoid false FAIL during fade).
- Extra diagnostics: print plan.size, first path, and every step index.
Style
- var-first everywhere; AppClock scheduling; Server.default.bind for Ndefs; no server.sync.
- Generated audio only; Option A enforced if available.
*/

(
var say, trace, assertXorAfter;
var ok, mpb, gui, useAdapter;
var ensureSources, applyViaAdapter, applyDirect, applyOne;
var plan, idx, gap, settle, runStep, kickOff;

/* logging helpers */
say   = { |msg| ("[ACCEPT] " ++ msg).postln };
trace = { |msg| ("[TRACE] "  ++ msg).postln };

/* delayed assertion to avoid crossfade overlap */
assertXorAfter = { |expectA, expectB, label, delaySeconds|
    var doCheck, delay;
    delay = delaySeconds ? 0.35; // default settle > 0.12 crossfade
    doCheck = {
        var a, b, okFlag, tag;
        a = Ndef(\chainA).isPlaying;
        b = Ndef(\chainB).isPlaying;
        okFlag = (a == expectA) and: { b == expectB };
        tag = if(okFlag) { "PASS" }{ "FAIL" };
        (tag ++ " — " ++ label ++ " (A=" ++ a ++ " B=" ++ b ++ ")").postln;
    };
    AppClock.sched(delay, { doCheck.value; nil });
};

/* guards */
ok = (~system.notNil) and: { ~system.pedalboard.notNil };
if(ok.not) { say.("⚠️ Bring-up first (Start Option B)"); ^nil; };
mpb = ~system.pedalboard;
gui = ~system.statusDisplay;
useAdapter = (~ct_applyOSCPathToMPB.notNil);

/* ensure generated sources & Option A */
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

/* application modes */
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

/* plan: Events with optional verify on switch */
plan = [
    ( idx: 1, total: 5, path: "/add/delay" ),
    ( idx: 2, total: 5, path: "/switch",           verifyDelay: 0.35, expectA: false, expectB: true,  label: "after first switch" ),
    ( idx: 3, total: 5, path: "/bypass/delay/on" ),
    ( idx: 4, total: 5, path: "/bypass/delay/off" ),
    ( idx: 5, total: 5, path: "/switch",           verifyDelay: 0.35, expectA: true,  expectB: false, label: "after second switch" )
];

/* extra instrumentation to confirm the plan really exists */
trace.("plan.size = " ++ plan.size);
if(plan.size > 0) {
    trace.("plan[0].path = " ++ plan[0][\path].asString);
} {
    say.("⚠️ plan is empty — aborting to avoid a no-op run."); ^nil;
};

idx    = 0;
gap    = 0.60;
settle = 0.35;

/* run one step, then re-schedule next */
runStep = {
    var step, path, haveVerify, label, eA, eB, vd;
    if(idx >= plan.size) { say.("done."); ^nil; };

    step = plan[idx];
    trace.("step " ++ step[\idx] ++ " / " ++ step[\total]);

    path = step[\path].asString;
    applyOne.value(path);

    haveVerify = step.includesKey(\verifyDelay);
    if(haveVerify) {
        vd   = step[\verifyDelay] ? settle;
        eA   = step[\expectA];
        eB   = step[\expectB];
        label= step[\label].asString;
        assertXorAfter.value(eA, eB, label, vd);
        AppClock.sched(vd.max(gap), { idx = idx + 1; runStep.value; nil });
    }{
        AppClock.sched(gap, { idx = idx + 1; runStep.value; nil });
    };
};

/* go */
ensureSources.value;
kickOff = {
    var scheduled;
    trace.("scheduling kickoff in 0.03s on AppClock…");
    scheduled = AppClock.sched(0.03, { runStep.value; nil });
    ("[TRACE] AppClock.sched → " ++ scheduled.asString).postln;
};
kickOff.value;
)
