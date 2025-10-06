// LPS_MasterMute_ON_AllCh.scd
// v0.1.0
// MD 20251006-1806

/*
Purpose
- Force full silence on ALL hardware output channels while keeping meters alive.
- Uses s.options.numOutputBusChannels to span the whole device.
Style
- var-first; Server.default.bind; AppClock for a small def-install delay; no server.sync.
*/

(
var s, defName, nChans, needAdd, addDef, startMute, msg;

s       = Server.default;
defName = \md_master_mute_all;
nChans  = (s.options.numOutputBusChannels ? 2).asInteger.max(2);
needAdd = SynthDescLib.global.at(defName.asSymbol).isNil;
msg     = { |t| ("[MasterMute-All] " ++ t).postln };

addDef = {
    Server.default.bind({
        SynthDef(defName, { |numOut = 2|
            var silent;
            silent = Silent.ar(numOut.max(2));      // silent vector with correct size
            ReplaceOut.ar(0, silent);               // replace the whole HW output bus
        }).add;
    });
    msg.("SynthDef " ++ defName.asString ++ " added");
};

startMute = {
    AppClock.sched(0.25, {
        Server.default.bind({
            if(~lps_masterMute.notNil and: { ~lps_masterMute.isPlaying }) {
                ~lps_masterMute.free;
            };
            // pass the channel count so the SynthDef builds the right width
            ~lps_masterMute = Synth.tail(s, defName, [\numOut, nChans]);
        });
        msg.("ON (tail-of-root, " ++ nChans.asString ++ " ch)");
        nil
    });
};

if(needAdd) { addDef.() };
startMute.();
)
