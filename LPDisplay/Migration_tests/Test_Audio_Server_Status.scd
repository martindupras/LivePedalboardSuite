// Test_Audio_Server_Status.scd
// v0.1.0
// MD 20251003-1302

/* Purpose/Style:
- Print quick status so you know if sound is even possible.
- Does not change server state.
*/

(
var serverRunning, outputBuses;

serverRunning = s.serverRunning;
outputBuses = s.options.numOutputBusChannels;

("Audio status — serverRunning: " ++ serverRunning.asString
 ++ ", outputBusChannels: " ++ outputBuses.asString).postln;

serverRunning.if({
    "OK: Server is running; you should hear sound if a synth/chain is started.".postln;
}, {
    "Server is NOT running. Boot it (or run your StartHere) before testing sound.".warn;
});
)