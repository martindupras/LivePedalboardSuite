// test 31tp8ve.scd
//

(
var baseFreq = 220.0; // A3
var stepsPerOctave = 31;
var numSteps = 62; // two octaves
var dur = 0.2;
var gap = 0.05;

Routine({
    numSteps.do { |step|
        var freq = baseFreq * (2 ** (step / stepsPerOctave));
        Synth(\play31tone, [\freq, freq]);
        dur.wait;
        gap.wait;
    };
}).play;

SynthDef(\play31tone, { |freq=220|
    var env = EnvGen.kr(Env.perc(0.01, 0.19), doneAction:2);
    var sig = SinOsc.ar(freq) * 0.2 * env;
    Out.ar(0, sig!2);
}).add;
)