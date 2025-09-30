// Feed_ChainA_TestTone_PlayChainA.scd
// v0.1.0
// MD timestamp: 2025-09-26 19:40 GMT+1

/*
Purpose
- Generate a gentle test tone and feed it into Ndef(\chainA) using <<>.
- Also calls Ndef(\chainA).play so you can hear it through the default output.

Style / Guard Rails
- Single () block; VAR-FIRST; no non-local returns; no server.sync.
*/

(
var freq, amp, msg;

freq = 220;      // adjust if you prefer
amp  = 0.10;     // safe level

Server.default.bind({
    // signal generator
    Ndef(\testmelody, { var sig;
        sig = SinOsc.ar(freq ! 2) * amp;
        sig
    });

    // connect strictly per your rule (left <<> right)
    Ndef(\chainA) <<> Ndef(\testmelody);

    // make it audible (optional but useful for sanity)
    Ndef(\chainA).play;
});

msg = "[FEED] Ndef(\\chainA) <<> Ndef(\\testmelody), playing @ " ++ freq ++ " Hz, amp=" ++ amp;
msg.postln;
msg
)
