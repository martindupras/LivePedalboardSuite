// 03_Sanity_Beep.scd
// v0.1.0
// MD 20250929-0918

(
// Purpose: Prove server + audio device are OK (audible 1-second beep).
// Style: var-first; no server.sync.

var playBeep;

playBeep = {
    if(s.serverRunning.not) { s.boot; s.waitForBoot({ "🔁 Server booted for beep.".postln; }) };
    {
        var env = Env.perc(0.005, 0.9).ar(doneAction:2);
        var sig = SinOsc.ar(880) * 0.1 * env;
        Out.ar(0, sig.dup);
    }.play;
    "🔊 Beep should be audible for ~1s.".postln;
};

playBeep.();
)
