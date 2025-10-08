// Repair_Reset_And_Instrument.scd
// v0.3.1
// MD 20251008-2056

/* Purpose
- Reset to a known-good state:
  • Define sources unconditionally.
  • Define sinks WITH in-sink SendPeakRMS (A id=2001, B id=2002).
  • Wire chainA<-testmelodyA, chainB<-testmelodyB.
  • Stop both sinks (silence).
  • Install OSC probes to count /peakrmsA and /peakrmsB messages.
Style
- Single block; var-first; no server.sync; no .isPlaying; no .play on taps.
*/

(
var initGraph, installProbes;

// --- define + wire everything deterministically ---
initGraph = {
    // Sources (unconditional)
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
        WhiteNoise.ar(1!2) * SinOsc.kr(7).range(0, 1) * 0.2
    });

    // Sinks with in-sink meters (A=2001, B=2002)
    Ndef(\chainA, {
        var x;
        x = \in.ar(0!2);
        SendPeakRMS.kr(x, 24, 3, '/peakrmsA', 2001);
        x
    }).ar(2);

    Ndef(\chainB, {
        var y;
        y = \in.ar(0!2);
        SendPeakRMS.kr(y, 24, 3, '/peakrmsB', 2002);
        y
    }).ar(2);

    // Wire inputs using .set (preferred)
    Ndef(\chainA).set(\in, Ndef(\testmelodyA));
    Ndef(\chainB).set(\in, Ndef(\testmelodyB));

    // Ensure silence at end of reset
    Ndef(\chainA).stop;
    Ndef(\chainB).stop;
};

installProbes = {
    ~probeAcount = 0;
    ~probeBcount = 0;
    ~probeAidList = List.new;
    ~probeBidList = List.new;

    OSCdef(\probeA, { |msg|
        var id;
        id = msg[1];
        ~probeAcount = ~probeAcount + 1;
        ~probeAidList.add(id);
    }, '/peakrmsA');

    OSCdef(\probeB, { |msg|
        var id;
        id = msg[1];
        ~probeBcount = ~probeBcount + 1;
        ~probeBidList.add(id);
    }, '/peakrmsB');
};

initGraph.value;
installProbes.value;

"RESET OK. Probes installed.".postln;
"Use: PlayA, SwitchToB, RemapA/B, ProbeSummary, FreeProbes".postln;
nil
)