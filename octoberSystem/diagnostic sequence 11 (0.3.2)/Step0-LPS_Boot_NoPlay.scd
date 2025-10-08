// Step0-LPS_Boot_NoPlay.scd
// v0.3.2
// MD 20251008-2106

(
~lpbSystem = ~lpbSystem;
if(~lpbSystem.isNil) {
    ~lpbSystem = LivePedalboardSystem.new;
    ~lpsWindow = ~lpbSystem.bringUpAll;  // -> a Window (may install AutoMeters)
    AppClock.sched(0.0, { ~lpsWindow.front; nil });
};

// Define/overwrite the test sources unconditionally
Ndef(\testmelodyA, {
    var t, e, f, sig;
    t = Impulse.kr(2.2);
    e = Decay2.kr(t, 0.01, 0.30);
    f = Demand.kr(t, 0, Dseq([220, 277.18, 329.63, 392], inf));
    sig = SinOsc.ar(f) * e * 0.22;
    sig ! 2
});
Ndef(\testmelodyB, {
    var t, e, f, sig;
    t = Impulse.kr(3.1);
    e = Decay2.kr(t, 0.02, 0.18);
    f = Demand.kr(t, 0, Dseq([392, 329.63, 246.94, 220, 246.94], inf));
    sig = Pulse.ar(f, 0.35) * e * 0.20;
    sig ! 2
});
Ndef(\srcBleeps, {
    var trig, freq, env, tone, sig;
    trig = Dust.kr(3);
    freq = TExpRand.kr(180, 2800, trig);
    env  = Decay2.kr(trig, 0.005, 0.20);
    tone = SinOsc.ar(freq + TRand.kr(-6, 6, trig));
    sig  = RLPF.ar(tone, (freq * 2).clip(80, 9000), 0.25) * env;
    Pan2.ar(sig, LFNoise1.kr(0.3).range(-0.6, 0.6)) * 0.2
});
Ndef(\srcPulsedNoise7, {
    WhiteNoise.ar(1!2) * SinOsc.kr(7).range(0,1) * 0.2
});

"BOOT: LPS up; sources defined.".postln;
)
