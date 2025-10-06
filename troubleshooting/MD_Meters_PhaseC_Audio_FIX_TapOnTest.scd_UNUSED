// MD_Meters_PhaseC_Audio_FIX_TapOnTest.scd
// v0.1.0
// MD timestamp: 2025-09-28 10:27 GMT+1

/*
Purpose
- Audio proof with the tap attached to Ndef(\testmelody) (the generator),
  so measured levels are guaranteed non-zero and derived from the actual test signal.
- Sends /md/levels A=2001 from the tap; B stays untouched.

Style / Guard Rails
- Single () block; VAR-FIRST throughout; no non-local returns; no server.sync.
*/

(
var hz, testFreq, testAmp, expectedRMS, banner, ensureProxy, attachTapOnTest;

// params
hz = 12;
testFreq = 220;
testAmp  = 0.20;                       // gentle, audible
expectedRMS = (testAmp / (2.sqrt));    // ≈ 0.1414

banner = { arg text; ("[MD_A_AUDIO_FIX] " ++ text).postln; };

// ensure Ndefs exist (not strictly needed for \testmelody, kept for consistency)
ensureProxy = { arg name, numCh;
    (Ndef(name).rate != \audio).if({
        Ndef(name).clear;
        Ndef(name).ar(numCh ? 2);
    });
};

// attach tap directly on \testmelody (NOT \chainA)
attachTapOnTest = { arg replyID;
    Ndef(\testmelody).filter(\proofTap, { arg inSig;
        var chans, l, r, ampL, ampR, trig;
        chans = inSig.asArray;
        l = (chans.size >= 1).if({ chans[0] }, { Silent.ar });
        r = (chans.size >= 2).if({ chans[1] }, { l });
        ampL = Lag.kr(Amplitude.kr(l, 0.01, 0.2), 0.08);
        ampR = Lag.kr(Amplitude.kr(r, 0.01, 0.2), 0.08);
        trig = Impulse.kr(hz);
        SendReply.kr(trig, '/md/levels', [ampL, ampR], replyID); // replyID=2001
        inSig
    });
};

// generate tone, feed chainA, and play (so you hear it)
Server.default.bind({
    var sig;
    sig = SinOsc.ar(testFreq ! 2) * testAmp;
    Ndef(\testmelody, { sig });
    ensureProxy.(\chainA, 2);
    Ndef(\chainA) <<> Ndef(\testmelody);
    Ndef(\chainA).play;
});

attachTapOnTest.(2001);

// finite console monitor for correlation (5 s)
OSCdef(\mdSpyA_fix).free;
OSCdef(\mdSpyA_fix, { arg msg;
    var isA, l, r;
    isA = (msg.size >= 5) and: { msg[2] == 2001 };
    isA.if({
        l = msg[3].asFloat; r = msg[4].asFloat;
        ("A_meas (L,R)=(" ++ l.round(0.003) ++ "," ++ r.round(0.003)
        ++ ")  vs expected_RMS≈" ++ expectedRMS.round(0.003)).postln;
    });
}, '/md/levels');

AppClock.sched(5.0, {
    OSCdef(\mdSpyA_fix).free;
    banner.("done (audio keeps playing; run MD_Cleanup_ChainA_Unfeed to stop).");
    nil
});

banner.("freq=" ++ testFreq ++ " Hz  amp=" ++ testAmp
    ++ "  expected_RMS≈" ++ expectedRMS.round(0.0001));
"-> MD_Meters_PhaseC_Audio_FIX_TapOnTest scheduled."
)
