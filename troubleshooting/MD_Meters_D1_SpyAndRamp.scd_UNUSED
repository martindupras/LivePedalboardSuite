// MD_Meters_D1_SpyAndRamp.scd
// v0.1.0
// MD timestamp: 2025-09-28 09:55 GMT+1

/*
Purpose
- First principles: prove the sclang process receives /md/levels.
- Spy counts A (2001) and B (2002) messages for 3 s while we send a ramp.
- If counts > 0, OSC is fine and PerfHUD isn't listening to /md/levels.
- If counts == 0, messages aren't arriving (wrong port/shape).

Style / Guard Rails
- Single () block; VAR-FIRST everywhere; finite; no server.sync.
*/

(
var hz, secs, sendToLang, sendRamp, aCount, bCount, total, spy, startAt, endAt, banner;

hz         = 12;
secs       = 3.0;
aCount     = 0;
bCount     = 0;
total      = 0;
banner     = { arg text; ("[MD_D1] " ++ text).postln; };
sendToLang = NetAddr("127.0.0.1", NetAddr.langPort);

// ---- Spy: capture ANY /md/levels messages and count A/B by replyID position ----
OSCdef(\md_levels_spy).free;
spy = OSCdef(\md_levels_spy, { arg msg, time, addr, port;
    var isA, isB;
    // Expect S1 standard: ['/md/levels', nodeID, replyID, L, R]
    isA = (msg.size >= 5) and: { msg[2] == 2001 };
    isB = (msg.size >= 5) and: { msg[2] == 2002 };
    isA.if({ aCount = aCount + 1; });
    isB.if({ bCount = bCount + 1; });
    total = total + 1;
}, '/md/levels');

// ---- Known-good sender: S1 standard shape [0, replyID, L, R] ----
sendRamp = {
    var t, aL, aR, now, endSend;
    now = thisThread.seconds;
    endSend = now + secs;
    AppClock.sched(0.0, {
        var cur;
        cur = thisThread.seconds;
        (cur < endSend).if({
            t  = (cur - now) / secs;
            aL = (0.9 * t).clip(0.0, 0.9);
            aR = (0.9 * (1 - t)).clip(0.0, 0.9);
            sendToLang.sendMsg('/md/levels', 0, 2001, aL, aR);  // A
            sendToLang.sendMsg('/md/levels', 0, 2002, 0.0, 0.0); // B held at 0
            (1.0 / hz)
        }, {
            nil
        });
    });
};

banner.("Starting spy + ramp for " ++ secs ++ " s…");
startAt = thisThread.seconds;
endAt   = startAt + secs;

sendRamp.();

AppClock.sched(secs + 0.1, {
    OSCdef(\md_levels_spy).free;
    banner.("Spy summary: total=" ++ total
        ++ "  A(2001)=" ++ aCount
        ++ "  B(2002)=" ++ bCount);
    "-> MD_Meters_D1_SpyAndRamp done.".postln;
    nil
});
"-> MD_Meters_D1_SpyAndRamp scheduled."
)
