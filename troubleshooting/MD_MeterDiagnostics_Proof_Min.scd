// MD_MeterDiagnostics_Proof_Min.scd
// v0.1.1 (var-first everywhere; correct /md/levels format)
// MD timestamp: 2025-09-27 19:52 GMT+1

/*
Purpose (first principles)
- \const: set A to exact values (no audio), prove GUI path.
- \ramp: animate A deterministically (no audio), prove timing.
- \audio: feed a sine into chainA, compute expected RMS, print measured levels,
  send live values to /md/levels (A=2001, B=2002) and correlate with what you hear.

Style / Guard Rails
- Single () block; VAR-FIRST in all blocks/closures; no non-local returns; no server.sync.
- AppClock only for finite drivers; loud banners.
*/

(
var phase, server, sendToLang, banner, postLine, hz, secs, startWhen, endWhen, tickTask;
var constAL, constAR;
var testFreq, testAmp, expectedRMS;
var ensureProxy, attachTap, makeTaps;
var sendPair;

// ===== PHASE SELECTOR =====
phase = \const;  // change to \ramp or \audio and re-run the SAME block

// ===== COMMON UTILS (statements OK after var decls) =====
server     = Server.default;
sendToLang = NetAddr("127.0.0.1", NetAddr.langPort);
banner     = { arg text; ("[MDPROOF] " ++ text).postln; };
postLine   = { arg text; text.postln; };
hz         = 12;
secs       = 4.0;
startWhen  = thisThread.seconds;
endWhen    = startWhen + secs;

// We send messages matching your GUI/meter path:
// ['/md/levels', nodeID, replyID, L, R]  (replyIDs: A=2001, B=2002)
sendPair = { arg aLR, bLR;
    var aL, aR, bL, bR;
    aL = aLR[0]; aR = aLR[1]; bL = bLR[0]; bR = bLR[1];
    sendToLang.sendMsg('/md/levels', 0, 2001, aL, aR);  // A
    sendToLang.sendMsg('/md/levels', 0, 2002, bL, bR);  // B
};

// ===== PHASE A params =====
constAL = 0.25;  // set any values 0..1 to prove exactness
constAR = 0.75;

// ===== PHASE C params =====
testFreq    = 220;
testAmp     = 0.20;                       // gentle
expectedRMS = (testAmp / (2.sqrt));       // RMS(sin) = A/√2

// ===== TAPS for PHASE C (server-side; var-first in closures) =====
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

        // Correct: replyID is 4th arg; values are ONLY [L, R]
        SendReply.kr(trig, '/md/levels', [ampL, ampR], replyID);

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

// ===== DRIVER =====
(phase == \const).if({
    var taskStart, taskEnd;
    taskStart = thisThread.seconds;
    taskEnd = taskStart + secs;
    banner.("PHASE A: set A=(" ++ constAL ++ "," ++ constAR ++ "), B=(0,0) for " ++ secs ++ " s");
    tickTask = AppClock.sched(0.0, {
        var now;
        now = thisThread.seconds;
        (now < taskEnd).if({
            sendPair.([constAL, constAR], [0.0, 0.0]);
            (1.0 / hz)
        }, {
            banner.("PHASE A done.");
            nil
        });
    });
});

(phase == \ramp).if({
    var taskStart, taskEnd;
    taskStart = thisThread.seconds;
    taskEnd = taskStart + secs;
    banner.("PHASE B: ramp A L:0→0.9, R:0.9→0 over " ++ secs ++ " s");
    tickTask = AppClock.sched(0.0, {
        var now, t, aL, aR;
        now = thisThread.seconds;
        (now < taskEnd).if({
            t  = (now - taskStart) / secs;         // 0..1
            aL = (0.9 * t).clip(0.0, 0.9);         // rise
            aR = (0.9 * (1 - t)).clip(0.0, 0.9);   // fall
            sendPair.([aL, aR], [0.0, 0.0]);
            (1.0 / hz)
        }, {
            banner.("PHASE B done.");
            nil
        });
    });
});

(phase == \audio).if({
    var spyStopAt;
    banner.("PHASE C: audio freq=" ++ testFreq ++ " Hz, amp=" ++ testAmp
        ++ "  (expected RMS≈" ++ expectedRMS.round(0.0001) ++ ")");

    Server.default.bind({
        var sig;
        sig = SinOsc.ar(testFreq ! 2) * testAmp;
        Ndef(\testmelody, { sig });
        Ndef(\chainA) <<> Ndef(\testmelody);
        Ndef(\chainA).play;
    });

    makeTaps.();

    spyStopAt = thisThread.seconds + 5.0;
    OSCdef(\mdSpyA, { arg msg, time, addr, port;
        var isA, l, r, line;
        isA = (msg.size >= 5) and: { msg[2] == 2001 };
        isA.if({
            l = msg[3].asFloat; r = msg[4].asFloat;
            line = "A_meas (L,R)=(" ++ l.round(0.001) ++ "," ++ r.round(0.001)
                ++ ")  vs expected_RMS≈" ++ expectedRMS.round(0.001);
            line.postln;
        });
    }, '/md/levels');

    AppClock.sched(5.0, {
        OSCdef(\mdSpyA).free;
        banner.("PHASE C done. Use Cleanup_ChainA_Unfeed later to stop audio.");
        nil
    });
});

"-> MD_MeterDiagnostics_Proof_Min scheduled.".postln;
)
