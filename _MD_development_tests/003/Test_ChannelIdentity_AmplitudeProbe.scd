// Test_ChannelIdentity_AmplitudeProbe.scd
// v0.2.2
// MD 20251012-0001

/*
Purpose
-------
Prove multi-channel identity using a deterministic, minimal probe:
- Source Ndef returns an n-channel vector with exactly one active channel.
- Passthrough Ndef reads with \in.ar(0 ! n) (explicit width), passes identity.
- Amplitude.kr + SendReply.kr publish a simple amplitude vector for inspection.
- A Poll inside the passthrough prints the actual input width seen by the synth.

Style / Constraints
-------------------
- Generated audio only (no SoundIn).
- Sources do NOT .play; only the passthrough .play(vol: 0.0) to compute silently.
- Deterministic connection: Ndef(\pass).set(\in, Ndef(\src)).
- Processors/sinks read with \in.ar(0 ! n) to force width at build time.
- var-first; descriptive lowercase names; no server.sync; AppClock for scheduling.

How to use
----------
Run Steps 1 → 5 in order.
Look for: `pass_in_width: n` (from Poll) and a one-hot amplitude mask at your active index.
Optionally re-run with ~numChannels = 1 or 2 and adjust ~activeIndex accordingly.
*/

// 1) Reset + parameters  ───────────────────────────────────────────────────────
(
s.waitForBoot({
    Ndef(\src).free;
    Ndef(\pass).free;
    if (OSCdef(\ampProbe).notNil) { OSCdef(\ampProbe).free };

    ~numChannels = 6;     // try 1, 2, or 6
    ~activeIndex = 3;     // 1-based
    ~testFreq    = 440;
    ~testAmp     = 0.1;   // linear
    ~probeHz     = 10;    // SendReply rate
    ~threshold   = 0.0005;
    ~runSeconds  = 3.0;

    ~lastAmp  = nil;
    ~lastMask = nil;

    "Channel identity test — n=% channels, active=%"
        .format(~numChannels, ~activeIndex).postln;
});
)

// 2) Probe receiver (/ampProbe)  ───────────────────────────────────────────────
(
var maxPrints, seen;

maxPrints = 12;
seen = 0;

// Our SendReply shape: ['/ampProbe', nodeID, replyID, a1 ... aN]
OSCdef(\ampProbe, { |msg|
    var amp, mask;

    amp  = msg.drop(3).asArray;
    mask = amp.collect { |x| x > (~threshold ? 0.0005) };

    ~lastAmp  = amp;
    ~lastMask = mask;

    if (seen < maxPrints) {
        ("AMP: " ++ amp.collect(_.round(1e-4)) ++ " | aboveThr: " ++ mask ++ " | n=" ++ amp.size).postln;
        seen = seen + 1;
        if (seen == maxPrints) { "…(muting further AMP prints)".postln; };
    };
}, '/ampProbe');
)

// 3) Passthrough (explicit width, amplitude probe, width Poll)  ───────────────
(
var replyID, trigHz, attack, release;

replyID = 1001;
trigHz  = ~probeHz ? 10;
attack  = 0.01;
release = 0.1;

Ndef(\pass).source = {
    var inSig, amp, trig, nChan;

    // Explicit n-channel width immediately (avoids mono adoption before mapping)
    inSig = \in.ar(0 ! ~numChannels);

    // Per-channel amplitude probe
    amp = Amplitude.kr(inSig, attack, release);

    // Periodic report to /ampProbe
    trig = Impulse.kr(trigHz);
    SendReply.kr(trig, "/ampProbe", amp, replyID);

    // Ground truth of passthrough input width (independent of hardware outputs)
    nChan = inSig.size; // array size known at build time
    Poll.kr(Impulse.kr(1), DC.kr(nChan), "pass_in_width");

    // Identity passthrough
    inSig
};
)

// 4) Source (one active channel)  ─────────────────────────────────────────────
(
Ndef(\src).source = {
    var sig, oneBasedIndex, i;

    oneBasedIndex = (~activeIndex ? 1).max(1).min(~numChannels);

    sig = Array.fill(~numChannels, { 0 });

    sig = sig.collect { |x, idx|
        i = idx + 1;
        if (i == oneBasedIndex) { SinOsc.ar(~testFreq) * ~testAmp } { 0 }
    };

    sig
};
)

// 5) Connect, run silently, one-hot assert, auto-stop  ────────────────────────
(
var stopTime;

// Deterministic connection (single path: src → pass)
Ndef(\pass).set(\in, Ndef(\src));

// Compute graph silently (AMP prints and Poll will show activity)
Ndef(\pass).play(vol: 0.0);

// Assertion: last mask must be one-hot at ~activeIndex
~assert_one_hot = {
    var amp, mask, trues, idx0, ok;

    amp  = ~lastAmp  ? #[];
    mask = ~lastMask ? #[];
    trues = mask.count({ |b| b == true });
    idx0  = mask.indexOf(true); // 0-based or nil
    ok    = (trues == 1) and: { (idx0 ? -1) == (~activeIndex - 1) };

    ok.if({
        ("PASS one-hot: idx=" ++ (~activeIndex) ++ " | amp=" ++ amp.collect(_.round(1e-4))).postln;
    }, {
        ("FAIL one-hot: trues=" ++ trues
         ++ " idx=" ++ (idx0.isNil.if({ "none" }, { (idx0 + 1).asString }))
         ++ " | expected=" ++ (~activeIndex)
         ++ " | amp=" ++ amp.collect(_.round(1e-4))).postln;
    });

    ok
};

// Run assertion after some probe frames arrive
AppClock.sched(1.0, { ~assert_one_hot.(); nil });

// Auto-stop (keeps console tidy; remove if you want it to run continuously)
stopTime = ~runSeconds ? 3.0;
AppClock.sched(stopTime, {
    "Stopping after % seconds…".format(stopTime).postln;
    Ndef(\pass).stop; nil
});
)