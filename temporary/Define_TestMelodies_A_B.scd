// Define_TestMelodies_A_B.scd
// v0.1.0
// MD 20251006-1715

/*
Purpose
- Two recognisably different, stereo test melodies with rests (meters drop) and safe level.
- A: slower pulses at ~2.0 Hz; B: faster pulses at ~3.1 Hz; different pitch sets.
Style
- var-first; Server.default.bind; no server.sync; lowercase names.
*/

(
var makeMelody;

makeMelody = { |nameSym, trigHz, midiSeq, amp=0.22|
    Server.default.bind({
        Ndef(nameSym, {
            var trig   = Impulse.kr(trigHz);
            var midi   = Dseq(midiSeq, inf);
            var noteOn = ToggleFF.kr(trig);              // 0/1
            var freq   = Demand.kr(trig, 0, midi).midicps;
            var env    = Decay2.kr(trig, 0.01, 0.20) * noteOn; // short; creates rests
            var sig    = SinOsc.ar(freq) * env * amp;
            [sig, sig]                                    // explicit stereo
        });
        Ndef(nameSym).ar(2);
    });
};

// A = slower, mid pitches, more space
makeMelody.(\testmelodyA, 2.0, [57, 60, 64, 69, 64, 60, 57]);
// B = faster, different register
makeMelody.(\testmelodyB, 3.1, [74, 71, 67, 62, 67, 71, 74]);

"Defined testmelodyA and testmelodyB".postln;
)