// NdefRoutingsSanityCheck.scd
// v1
// MD 20251007-0917

// This is working.

// Evaluate these first.


    Ndef(\testmelodyA, {
        var t = Impulse.kr(2.2);
        var e = Decay2.kr(t, 0.01, 0.30);
        var f = Demand.kr(t, 0, Dseq([220, 277.18, 329.63, 392], inf));
        (SinOsc.ar(f) * e * 0.22)!2
    });
    Ndef(\testmelodyB, {
        var t = Impulse.kr(3.1);
        var e = Decay2.kr(t, 0.02, 0.18);
        var f = Demand.kr(t, 0, Dseq([392, 329.63, 246.94, 220, 246.94], inf));
        (Pulse.ar(f, 0.35) * e * 0.20)!2
    });








// Evaluate step by step.
Ndef(\testmelodyA).play; // this works, A is audible
Ndef(\testmelodyA).stop; // this works, A is playing but not audible
Ndef(\chainA).play; // plays but is silent right now
Ndef(\chainA).source =  Ndef(\testmelodyA); // route melody into chain; audible
Ndef(\chainA).source =  Ndef(\testmelodyB); // route melody into chain; audible
Ndef(\chainA).stop; // plays but is silent right now