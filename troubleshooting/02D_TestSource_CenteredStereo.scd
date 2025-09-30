// 02D_TestSource_CenteredStereo_Pulsed.scd
// v0.1.1
// MD 20250929-0948

(
// Purpose
// - Centered stereo pulses (equal L/R), easy to see on meters without drone.
// Style
// - var-first; server ops in Server.default.bind.

var install;

install = {
    Server.default.bind({
        Ndef(\testmelody, {
            var trig = Impulse.kr(2);                // 2 pulses per second
            var env  = Decay2.kr(trig, 0.01, 0.22);  // short visual envelope
            var sig  = SinOsc.ar(440) * env * 0.30;  // moderate level
            [sig, sig]                               // equal L/R
        });
        Ndef(\testmelody).ar(2);
    });
    "🎛️ testmelody set to centered stereo pulses (equal L/R).".postln;
};

install.value;
)
