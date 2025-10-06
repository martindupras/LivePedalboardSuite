// Switch_WhenIdle_Quiet.scd
// v0.1.0
// MD 20251006-1706

/*
Purpose
- Send "/switch" once MPB isn't busy; times out gracefully and sends anyway.
Style
- var-first; uses AppClock; no server.sync.
*/

(
var sendWhenIdle, maxWait, checkEvery, deadline;

sendWhenIdle = { |path="/switch", waitSec=2.0, stepSec=0.1|
    var lps = ~lps, cm, idle;
    if(lps.isNil) { " ~lps is nil; run Start_LPS_with_LPDisplay.scd first.".warn; ^this };

    cm = lps.commandManager;
    deadline = SystemClock.seconds + waitSec;

    Routine({
        loop {
            idle = (lps.pedalboard.tryPerform(\isBusy) ? false).not; // assume idle if no flag
            if(idle) {
                cm.queueExportCallback.(path);
                ("[Switch_WhenIdle] sent " ++ path).postln;
                break;
            };
            if(SystemClock.seconds > deadline) {
                "[Switch_WhenIdle] timeout; sending anyway".warn;
                cm.queueExportCallback.(path);
                break;
            };
            stepSec.wait;
        }
    }).play(AppClock);
};

// call it:
sendWhenIdle.("/switch", 2.0, 0.1);
)