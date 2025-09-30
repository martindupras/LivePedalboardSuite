// MD_Meters_PhaseC_Audio.scd
// v0.1.0
// MD timestamp: 2025-09-27 19:58 GMT+1

/*
Purpose
- Feed a sine into Ndef(\chainA), attach taps that SendReply /md/levels (A=2001, B=2002).
- Print expected RMS (A/√2) and measured A levels in console for 5s.
*/

(
var hz, testFreq, testAmp, expectedRMS, banner, ensureProxy, attachTap, makeTaps;

hz = 12;
testFreq = 220;
testAmp  = 0.20;
expectedRMS = (testAmp / (2.sqrt)); // ≈0.1414 for 0.2

banner = { arg text; var t; t = text; ("[MD_A_AUDIO] " ++ t).postln; };

ensureProxy = { arg name, numCh;
    (Ndef(name).rate != \audio).if({
        Ndef(name).clear;
        Ndef(name).ar(numCh ? 2);
    });
};

attachTap = { arg name, key, replyID;
    Ndef(name).filter(key, { arg inSig;
        var chans, l, r, ampL, ampR, trig;
        chans = inSig.asArray;
        l = (chans.size >= 1).if({ chans[0] }, { Silent.ar });
        r = (chans.size >= 2).if({ chans[1] }, { l });
        ampL = Lag.kr(Amplitude.kr(l, 0.01, 0.2), 0.08);
        ampR = Lag.kr(Amplitude.kr(r, 0.01, 0.2), 0.08);
        trig = Impulse.kr(hz);
        SendReply.kr(trig, '/md/levels', [ampL, ampR], replyID);  // replyID in 4th arg (correct)
        inSig
    });
};

makeTaps = {
    Server.default.bind({
        ensureProxy.(\chainA, 2);
        ensureProxy.(\chainB, 2);
        attachTap.(\chainA, \eodTapA, 2001);
        attachTap.(\chainB, \eodTapB, 2002);
    });
    banner.("Taps attached A=2001, B=2002 @" ++ hz ++ " Hz");
};

// Feed test tone and play
Server.default.bind({
    var sig;
    sig = SinOsc.ar(testFreq ! 2) * testAmp;
    Ndef(\testmelody, { sig });
    Ndef(\chainA) <<> Ndef(\testmelody);
    Ndef(\chainA).play;
});

makeTaps.();

OSCdef(\mdSpyA).free;  // ensure clean
OSCdef(\mdSpyA, { arg msg;
    var isA, l, r, line;
    isA = (msg.size >= 5) and: { msg[2] == 2001 };  // replyID position
    isA.if({
        l = msg[3].asFloat; r = msg[4].asFloat;
        line = "A_meas (L,R)=(" ++ l.round(0.001) ++ "," ++ r.round(0.001)
            ++ ")  vs expected_RMS≈" ++ expectedRMS.round(0.001);
        line.postln;
    });
}, '/md/levels');

AppClock.sched(5.0, {
    OSCdef(\mdSpyA).free;
    banner.("done (audio still playing; run MD_Cleanup_ChainA_Unfeed to stop).");
    nil
});

banner.("freq=" ++ testFreq ++ " Hz  amp=" ++ testAmp
    ++ "  expected_RMS≈" ++ expectedRMS.round(0.0001));
"-> MD_Meters_PhaseC_Audio scheduled."
)
