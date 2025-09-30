// MD_Meters_PhaseB_Ramp.scd
// v0.1.0
// MD timestamp: 2025-09-27 19:58 GMT+1

/*
Purpose
- Animate A for 4s: L ramps 0→0.9, R ramps 0.9→0. B stays 0.
*/

(
var hz, secs, sendToLang, sendPair, startAt, endAt, banner, task;

hz = 12;
secs = 4.0;
banner = { arg text; var t; t = text; ("[MD_A_RAMP] " ++ t).postln; };
sendToLang = NetAddr("127.0.0.1", NetAddr.langPort);

sendPair = { arg aLR, bLR;
    var a0, a1, b0, b1;
    a0 = aLR[0]; a1 = aLR[1]; b0 = bLR[0]; b1 = bLR[1];
    sendToLang.sendMsg('/md/levels', 0, 2001, a0, a1);
    sendToLang.sendMsg('/md/levels', 0, 2002, b0, b1);
};

startAt = thisThread.seconds; endAt = startAt + secs;

banner.("Ramp A L:0→0.9, R:0.9→0 over " ++ secs ++ " s");
task = AppClock.sched(0.0, {
    var now, t, aL, aR;
    now = thisThread.seconds;
    (now < endAt).if({
        t = (now - startAt) / secs;          // 0..1
        aL = (0.9 * t).clip(0.0, 0.9);       // rise
        aR = (0.9 * (1 - t)).clip(0.0, 0.9); // fall
        sendPair.([aL, aR], [0.0, 0.0]);
        (1.0 / hz)
    }, {
        banner.("done.");
        nil
    });
});
"-> MD_Meters_PhaseB_Ramp scheduled."
)
