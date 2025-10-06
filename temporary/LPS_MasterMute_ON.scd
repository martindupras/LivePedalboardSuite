// LPS_MasterMute_ON.scd
// v0.1.1
// MD 20251006-1736

/*
Purpose
- Force full silence at the hardware outputs while keeping meters alive.
- Adds SynthDef if missing, then starts the mute synth after a short delay so the def is received.
Style
- var-first; Server.default.bind; AppClock for timing; no server.sync; no non-local returns.
Usage
- Run AFTER your usual starter (so server + chains/meters exist).
*/

(
var s, defName, needAdd, addDef, startMute;

s = Server.default;
defName = \md_master_mute;
needAdd = SynthDescLib.global.at(defName.asSymbol).isNil;

addDef = {
    Server.default.bind({
        SynthDef(defName, {
            // Replace main output with silence (stereo) at the very end of the graph.
            ReplaceOut.ar(0, Silent.ar(2));
        }).add;
    });
    ("[MasterMute] SynthDef " ++ defName.asString ++ " added").postln;
};

startMute = {
    // Give the server a short moment to receive the def before /s_new
    AppClock.sched(0.25, {
        Server.default.bind({
            // Avoid duplicates: free prior mute if still running
            if(~lps_masterMute.notNil and: { ~lps_masterMute.isPlaying }) {
                ~lps_masterMute.free;
            };
            ~lps_masterMute = Synth.tail(s, defName);
        });
        "[MasterMute] ON (tail-of-root)".postln;
        nil
    });
};

if(needAdd) { addDef.() };
startMute.();
)