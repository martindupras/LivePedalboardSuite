// 02S_AssertStereo_ChainAB_and_Retap_SAFE.scd
// v0.1.1
// MD 20250929-1120

/* Purpose
   - Assert stereo + playing for Ndef(\chainA) and Ndef(\chainB) WITHOUT muting/rewiring.
   - (Re)install safe visual taps that send /md/levels (replyIDs A=2001, B=2002).
   - Use unique filter keys and ALWAYS return 'in' (pure pass-through).
   - No server.sync; Server.default.bind for server ops; var-first; lowercase.

   Notes
   - This script does NOT touch sources, OSCdefs, or HUD listeners.
   - If an older tap with the same key exists, .filter replaces it safely.
*/

(
var rateHz, atk, rel, floorAmp, path;
var busA, busB, playA, playB, chA, chB, warn;

rateHz   = 24;
atk      = 0.01;
rel      = 0.20;
floorAmp = 1e-5;
path     = "/md/levels";

warn = { |txt| ("[02S_SAFE] " ++ txt).warn };

// --- assert stereo/playing & re-tap (no frees, no stops)
Server.default.bind({
    // ensure AR 2-ch busses are alive
    Ndef(\chainA).ar(2);
    Ndef(\chainB).ar(2);

    // quick diagnostics (posts only; never mutates play state)
    busA = Ndef(\chainA).bus;
    busB = Ndef(\chainB).bus;
    playA = Ndef(\chainA).isPlaying;
    playB = Ndef(\chainB).isPlaying;
    chA = busA.notNil.if({ busA.numChannels }, { -1 });
    chB = busB.notNil.if({ busB.numChannels }, { -1 });

    ("[02S_SAFE] A: playing=" ++ playA ++ " ch=" ++ chA).postln;
    ("[02S_SAFE] B: playing=" ++ playB ++ " ch=" ++ chB).postln;

    if(chA != 2) { warn.("chainA bus is not stereo (" ++ chA ++ "); enforcing ar(2)"); Ndef(\chainA).ar(2); };
    if(chB != 2) { warn.("chainB bus is not stereo (" ++ chB ++ "); enforcing ar(2)"); Ndef(\chainB).ar(2); };

    // --- SAFE visual taps (A=2001, B=2002); return 'in'
    Ndef(\chainA).filter(\mdVisTapA, { |in|
        var sig, aL, aR;
        sig = in.isArray.if({ in }, { [in, in] });
        aL = Amplitude.kr(sig[0], atk, rel).clip(floorAmp, 1.0);
        aR = Amplitude.kr(sig[1], atk, rel).clip(floorAmp, 1.0);
        SendReply.kr(Impulse.kr(rateHz), path, [aL, aR], 2001);
        in
    });

    Ndef(\chainB).filter(\mdVisTapB, { |in|
        var sig, aL, aR;
        sig = in.isArray.if({ in }, { [in, in] });
        aL = Amplitude.kr(sig[0], atk, rel).clip(floorAmp, 1.0);
        aR = Amplitude.kr(sig[1], atk, rel).clip(floorAmp, 1.0);
        SendReply.kr(Impulse.kr(rateHz), path, [aL, aR], 2002);
        in
    });
});
"[*] 02S_SAFE: stereo asserted; taps (A=2001,B=2002) sending to /md/levels".postln;
)
