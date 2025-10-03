// Test_Play_ShortBeep.scd
// v0.1.0
// MD 20251003-1302

/* Purpose/Style:
- Play a short generated beep (no SoundIn, stereo) to confirm audio path.
- Safe: independent SynthDef with doneAction:2; no server.sync.
*/

(
var synthDefName, makeIfMissing, startBeep, startedSynth;

synthDefName = \md_shortBeep;

makeIfMissing = {
    SynthDescLib.global.at(synthDefName).isNil.if({
        SynthDef(synthDefName, {
            var amplitude, envelope, signal;
            amplitude = 0.2; // keep it gentle
            envelope = Env.perc(0.01, 0.35, curve: -4).kr(doneAction: 2);
            signal = SinOsc.ar(880) * envelope * amplitude;
            Out.ar(0, [signal, signal]);  // stereo
        }).add;
        "Defined SynthDef(\\md_shortBeep).".postln;
    });
};

startBeep = {
    s.serverRunning.if({
        startedSynth = Synth(synthDefName);
        ("Started " ++ synthDefName.asString ++ " -> " ++ startedSynth.asString).postln;
    }, {
        "Server is not running; beep skipped.".warn;
    });
};

makeIfMissing.();
startBeep.();
)