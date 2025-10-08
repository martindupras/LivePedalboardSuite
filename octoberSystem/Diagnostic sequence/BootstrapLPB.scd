// BootstrapLPB.scd
// v0.0.8
// MD 20251008-1734

/* Purpose
- Bring up LivePedalboardSystem (opens its own LPDisplay).
- Define test sources only (no mapping, no playback).
Style
- Single block; var-first; server ops in Server.default.bind; GUI on AppClock.
- Returns '-> a Window'.
*/

(
var lpbSystem, displayWindow, ensureSources;

// Define test sources (safe if they already exist)
ensureSources = {
    Server.default.bind({
        // A: melodic sine line
        if(Ndef(\testmelodyA).source.isNil) {
            Ndef(\testmelodyA, {
                var t, e, f, sig;
                t = Impulse.kr(2.2);
                e = Decay2.kr(t, 0.01, 0.30);
                f = Demand.kr(t, 0, Dseq([220, 277.18, 329.63, 392], inf));
                sig = SinOsc.ar(f) * e * 0.22;
                sig ! 2
            });
        };
        // B: melodic pulse line
        if(Ndef(\testmelodyB).source.isNil) {
            Ndef(\testmelodyB, {
                var t, e, f, sig;
                t = Impulse.kr(3.1);
                e = Decay2.kr(t, 0.02, 0.18);
                f = Demand.kr(t, 0, Dseq([392, 329.63, 246.94, 220, 246.94], inf));
                sig = Pulse.ar(f, 0.35) * e * 0.20;
                sig ! 2
            });
        };
        // Alt: random bleeps
        if(Ndef(\srcBleeps).source.isNil) {
            Ndef(\srcBleeps, {
                var trig, freq, env, tone, sig;
                trig = Dust.kr(3);
                freq = TExpRand.kr(180, 2800, trig);
                env  = Decay2.kr(trig, 0.005, 0.20);
                tone = SinOsc.ar(freq + TRand.kr(-6, 6, trig));
                sig  = RLPF.ar(tone, (freq * 2).clip(80, 9000), 0.25) * env;
                Pan2.ar(sig, LFNoise1.kr(0.3).range(-0.6, 0.6)) * 0.2
            });
        };
        // Alt: pulsed white noise
        if(Ndef(\srcPulsedNoise7).source.isNil) {
            Ndef(\srcPulsedNoise7, {
                var gate;
                gate = SinOsc.kr(7).range(0, 1);
                WhiteNoise.ar(1 ! 2) * gate * 0.2
            });
        };
    });
    nil
};

// Bring up LPS (opens its own LPDisplay)
lpbSystem = LivePedalboardSystem.new;
displayWindow = lpbSystem.bringUpAll;  // -> a Window

// Define sources only; no mapping, no play
ensureSources.value;

// Front the window and return
AppClock.sched(0.0, { var nothing; if(displayWindow.notNil) { displayWindow.front }; nil });
displayWindow
)
