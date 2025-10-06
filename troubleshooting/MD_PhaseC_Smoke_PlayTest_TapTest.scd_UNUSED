// MD_PhaseC_Smoke_PlayTest_TapTest.scd
// v0.1.0
// MD timestamp: 2025-09-28 10:58 GMT+1

/*
Purpose
1) Force Ndef(\testmelody) to run by playing it directly.
2) Prove the tap executes by sending a constant 0.5 for 2s (meters must move).
3) Switch the tap to real Amplitude.kr for 3s and print measured vs expected RMS.
All updates go to /md/levels A=2001 (B untouched).

Style / Guard Rails
- Single () block; VAR-FIRST; no non-local returns; no server.sync; finite.
*/

(
var hz, testFreq, testAmp, expectedRMS, banner, now,
    installConstantTap, installAmplitudeTap, removeTap, spy, stopSpyAt;

hz = 12;
testFreq = 220;
testAmp  = 0.20;
expectedRMS = (testAmp / (2.sqrt)); // ≈0.1414

banner = { arg text; ("[MD_SMOKE] " ++ text).postln; };

// 0) Ensure a fresh, running generator (play directly so the proxy surely runs)
Server.default.bind({
    var sig;
    sig = SinOsc.ar(testFreq ! 2) * testAmp;
    Ndef(\testmelody, { sig });
    Ndef(\testmelody).play; // <-- force run; independent of \chainA
});
banner.("testmelody playing @ " ++ testFreq ++ " Hz, amp=" ++ testAmp);

// helper: remove our tap cleanly
removeTap = {
    Ndef(\testmelody).filter(\proofTap, { arg inSig; inSig });
};

// 1) Tap variant A: constant 0.5 for 2s (meters must move)
installConstantTap = {
    Ndef(\testmelody).filter(\proofTap, { arg inSig;
        var trig, l, r;
        trig = Impulse.kr(hz);
        l = 0.5; r = 0.5;
        SendReply.kr(trig, '/md/levels', [l, r], 2001);
        inSig
    });
    banner.("tap A: CONSTANT 0.5 for 2s (A should show ~0.5)");
};

// 2) Tap variant B: real amplitude for 3s (print measured vs expected)
installAmplitudeTap = {
    Ndef(\testmelody).filter(\proofTap, { arg inSig;
        var chans, l, r, ampL, ampR, trig;
        chans = inSig.asArray;
        l = (chans.size >= 1).if({ chans[0] }, { Silent.ar });
        r = (chans.size >= 2).if({ chans[1] }, { l });
        ampL = Lag.kr(Amplitude.kr(l, 0.01, 0.2), 0.08);
        ampR = Lag.kr(Amplitude.kr(r, 0.01, 0.2), 0.08);
        trig = Impulse.kr(hz);
        SendReply.kr(trig, '/md/levels', [ampL, ampR], 2001);
        inSig
    });
    banner.("tap B: Amplitude.kr for 3s (console prints A_meas vs expected RMS)");
};

// Spy: show arriving values for A=2001 only
OSCdef(\mdSmokeSpy).free;
spy = OSCdef(\mdSmokeSpy, { arg msg;
    var isA, l, r;
    isA = (msg.size >= 5) and: { msg[2] == 2001 };
    isA.if({
        l = msg[3].asFloat; r = msg[4].asFloat;
        ("A_meas (L,R)=(" ++ l.round(0.003) ++ "," ++ r.round(0.003)
            ++ ")  vs expected_RMS≈" ++ expectedRMS.round(0.003)).postln;
    });
}, '/md/levels');

// Schedule: 0..2s constant 0.5, 2..5s amplitude, stop spy
now = thisThread.seconds;

AppClock.sched(0.0, { installConstantTap.(); 2.0 });
AppClock.sched(2.0, { installAmplitudeTap.(); 3.0 });
stopSpyAt = now + 5.0;
AppClock.sched(5.0, {
    removeTap.();
    OSCdef(\mdSmokeSpy).free;
    banner.("done (testmelody still playing; stop with MD_Cleanup_ChainA_Unfeed if needed).");
    nil
});

"-> MD_PhaseC_Smoke_PlayTest_TapTest scheduled."
)
