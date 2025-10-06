// Test_Switch_WhenIdle_OneShot.scd
// v0.1.0
// MD 20251006-1753

/*
Purpose
- Send "/switch" once, *only when MPB is idle* (≤ 2 s wait).
- Prints ACTIVE before and after; does NOT call refreshDisplay (won't overwrite visual).
Style
- var-first; AppClock timing; no server.sync; no non-local returns.
Pre-req
- Start_LPS_with_LPDisplay.scd already ran in this session (so ~lps exists).
- Master mute can remain ON (meters still move, no audio).
*/

(
var lps, cm, mpb, waitSec, stepSec, deadline;
var getActive, isBusy, sendSwitch, pollAndSend, postAfter;

lps = ~lps;

if (lps.isNil) {
    "[SwitchOneShot] ~lps is nil; run Start_LPS_with_LPDisplay.scd first.".warn;
} {
    cm = lps.commandManager;
    mpb = lps.pedalboard;

    if (cm.isNil or: { cm.queueExportCallback.isNil }) {
        "[SwitchOneShot] queueExportCallback is nil; bridge not installed.".warn;
    } {
        // --- config
        waitSec  = 2.0;
        stepSec  = 0.10;
        deadline = SystemClock.seconds + waitSec;

        // --- helpers (var-first inside each)
        getActive = {
            var k;
            k = mpb.tryPerform(\currentKey);
            ("[SwitchOneShot] ACTIVE = " ++ (k ? \A).asString).postln;
        };

        isBusy = {
            var flag;
            flag = mpb.tryPerform(\isBusy);
            flag = flag ? false; // treat nil as not-busy
            flag
        };

        sendSwitch = {
            var msg;
            msg = "/switch";
            cm.queueExportCallback.(msg);
            ("[SwitchOneShot] sent " ++ msg).postln;
        };

        postAfter = {
            AppClock.sched(0.35, {
                getActive.();
                "[SwitchOneShot] done.".postln;
                nil
            });
        };

        // --- run: idle-wait then send once
        ("[SwitchOneShot] starting; waiting up to " ++ waitSec ++ "s for idle…").postln;
        getActive.();

        pollAndSend = Routine({
            var sent, now, busy;
            sent = false;
            while({ sent.not and: { SystemClock.seconds < deadline } }, {
                busy = isBusy.();
                if (busy.not) {
                    sendSwitch.();
                    sent = true;
                } {
                    stepSec.wait;
                };
            });

            if (sent.not) {
                "[SwitchOneShot] timeout; sending anyway".warn;
                sendSwitch.();
            };

            postAfter.();
        });

        pollAndSend.play(AppClock);
    };
};
)