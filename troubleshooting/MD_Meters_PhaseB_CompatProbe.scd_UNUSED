// MD_Meters_PhaseB_CompatProbe.scd
// v0.1.0
// MD timestamp: 2025-09-27 20:12 GMT+1

/*
Purpose
- Determine which /md/levels message shape your PerfHUD v0.5.4 consumes.
- Sends the same ramp in three 2s segments:
  A) S1 standard: ['/md/levels', nodeID=0, replyID=2001/2002, L, R]
  B) S0 legacy:  ['/md/levels', replyID=2001/2002, L, R]            // first arg after path is replyID
  C) S2 variant: ['/md/levels', nodeID=0, 0, replyID, L, R]         // mimics old SendReply misuse

Style / Guard Rails
- Single () block; VAR-FIRST; no non-local returns; no server.sync.
*/

(
var hz, secsEach, sendToLang, banner, sendS1, sendS0, sendS2, startAt, segmentDur, schedSeg;

// Params
hz       = 12;      // updates per second
secsEach = 2.0;     // duration per segment (A/B/C)

// Utils
banner     = { arg text; ("[MD_COMPAT] " ++ text).postln; };
sendToLang = NetAddr("127.0.0.1", NetAddr.langPort);

// --- Three message shapes ---
sendS1 = { arg aL, aR, bL, bR;
    // S1 standard: ['/md/levels', 0, 2001, L, R]
    sendToLang.sendMsg('/md/levels', 0, 2001, aL, aR);  // A
    sendToLang.sendMsg('/md/levels', 0, 2002, bL, bR);  // B
};

sendS0 = { arg aL, aR, bL, bR;
    // S0 legacy: ['/md/levels', 2001, L, R]
    sendToLang.sendMsg('/md/levels', 2001, aL, aR);     // A
    sendToLang.sendMsg('/md/levels', 2002, bL, bR);     // B
};

sendS2 = { arg aL, aR, bL, bR;
    // S2 variant: ['/md/levels', 0, 0, 2001, L, R]
    sendToLang.sendMsg('/md/levels', 0, 0, 2001, aL, aR);  // A
    sendToLang.sendMsg('/md/levels', 0, 0, 2002, bL, bR);  // B
};

// --- Scheduler for one segment with the given sender ---
schedSeg = { arg label, senderFunc;
    var segStart, segEnd;
    segStart = thisThread.seconds;
    segEnd   = segStart + secsEach;
    banner.("SEG " ++ label ++ " — ramp A: L 0→0.9, R 0.9→0 (" ++ secsEach ++ " s)");
    AppClock.sched(0.0, {
        var now, t, aL, aR;
        now = thisThread.seconds;
        (now < segEnd).if({
            t  = (now - segStart) / secsEach;
            aL = (0.9 * t).clip(0.0, 0.9);
            aR = (0.9 * (1 - t)).clip(0.0, 0.9);
            senderFunc.value(aL, aR, 0.0, 0.0);  // B kept at 0
            (1.0 / hz)
        }, {
            banner.("SEG " ++ label ++ " done.");
            nil
        });
    });
};

// --- Run the three segments back-to-back ---
AppClock.sched(0.0, { schedSeg.("A (S1 standard: [0,replyID,L,R])", sendS1); secsEach });
AppClock.sched(secsEach, { schedSeg.("B (S0 legacy: [replyID,L,R])",   sendS0); secsEach });
AppClock.sched(secsEach*2, { schedSeg.("C (S2 variant: [0,0,replyID,L,R])", sendS2); nil });

"-> MD_Meters_PhaseB_CompatProbe scheduled (6 s total).".postln;
)
