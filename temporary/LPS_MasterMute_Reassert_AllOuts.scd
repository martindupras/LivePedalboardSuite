// LPS_MasterMute_Reassert_AllOuts.scd
// v0.1.0
// MD 20251006-1755

/*
Purpose
- Force full silence on *all* hardware output channels while keeping meters alive.
- Builds a channel-count-specific SynthDef and starts it at the tail of the root group.
Style
- var-first; Server.default.bind; AppClock for timing; no server.sync; no non-local returns.
Usage
- Run AFTER your starter has brought the system up (LPDisplay visible, meters moving).
*/

(
var s, numOut, defName, defExists, makeDef, startMute;

s = Server.default;
numOut = s.options.numOutputBusChannels.max(2); // ensure at least stereo
defName = ("md_master_mute_" ++ numOut).asSymbol;
defExists = SynthDescLib.global.at(defName).notNil;

// Build and add a mute SynthDef for *exactly* numOut channels (language-side array)
makeDef = {
    Server.default.bind({
        SynthDef(defName, {
            var zeros;
            zeros = Array.fill(numOut, { Silent.ar(1) }); // create N silent channels
            ReplaceOut.ar(0, zeros);                      // override main output bus 0..N-1
        }).add;
    });
    ("[MasterMute] SynthDef " ++ defName.asString ++ " added (" ++ numOut ++ " ch)").postln;
};

// Start the mute synth at the tail; small defer so the def is on the server
startMute = {
    AppClock.sched(0.30, {
        Server.default.bind({
            if(~lps_masterMute.notNil and: { ~lps_masterMute.isPlaying }) { ~lps_masterMute.free; };
            ~lps_masterMute = Synth.tail(s, defName);
        });
        ("[MasterMute] ON (tail-of-root, " ++ numOut ++ " ch)").postln;
        nil
    });
};

if(defExists.not) { makeDef.() };
startMute.();
)