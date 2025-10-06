// MD_Meters_PhaseA_Const.scd
// v0.1.0
// MD timestamp: 2025-09-27 19:58 GMT+1

/*
Purpose
- Drive meters to exact values A=(0.25, 0.75), B=(0, 0) for 4s via /md/levels.

Style / Guard Rails
- Single () block; VAR-FIRST; finite; no server.sync.
*/

(
var hz, secs, sendToLang, sendPair, aL, aR, bL, bR, startAt, endAt, banner, task;

hz = 12;
secs = 4.0;
banner = { arg text; var t; t = text; ("[MD_A_CONST] " ++ t).postln; };
sendToLang = NetAddr("127.0.0.1", NetAddr.langPort);

sendPair = { arg aLR, bLR;
    var a0, a1, b0, b1;
    a0 = aLR[0]; a1 = aLR[1]; b0 = bLR[0]; b1 = bLR[1];
    sendToLang.sendMsg('/md/levels', 0, 2001, a0, a1);  // A
    sendToLang.sendMsg('/md/levels', 0, 2002, b0, b1);  // B
};

aL = 0.25; aR = 0.75; bL = 0.0; bR = 0.0;
startAt = thisThread.seconds; endAt = startAt + secs;

banner.("A=(" ++ aL ++ "," ++ aR ++ "), B=(0,0) for " ++ secs ++ " s");
task = AppClock.sched(0.0, {
    var now;
    now = thisThread.seconds;
    (now < endAt).if({
        sendPair.([aL, aR], [bL, bR]);
        (1.0 / hz)
    }, {
        banner.("done.");
        nil
    });
});
"-> MD_Meters_PhaseA_Const scheduled."
)
