// Test_Switch_Once_Quiet.scd
// v0.1.1
// MD 20251006-1744

/*
Purpose
- Send /switch one time, silently.
- Waits for MagicPedalboard idle (<= 2 s); if still busy, retries twice with 300 ms spacing.
Style
- var-first everywhere; no server.sync; AppClock for timing; no non-local returns.
Pre-req
- You have already run Start_LPS_with_LPDisplay.scd in this session (so ~lps exists).
- Master mute can remain ON (meters still move).
*/

(
var lps, cm, waitSec, stepSec, deadline, attempt, maxAttempts, sendOnce, runner;

lps = ~lps;
if (lps.isNil) {
    "[Switch] ~lps is nil; run Start_LPS_with_LPDisplay.scd first.".warn;
} {
    cm = lps.commandManager;
    if (cm.isNil or: { cm.queueExportCallback.isNil }) {
        "[Switch] queueExportCallback is nil; ensure the starter installed the bridge.".warn;
    } {
        waitSec = 2.0;
        stepSec = 0.1;
        deadline = SystemClock.seconds + waitSec;
        attempt = 0;
        maxAttempts = 2;

        sendOnce = {
            var msg;
            msg = "/switch";
            cm.queueExportCallback.(msg);
            ("[Switch] sent " ++ msg ++ " (attempt " ++ (attempt + 1) ++ ")").postln;
        };

        runner = Routine({
            var done, idle, now;
            done = false; idle = false; now = 0.0;

            // Wait up to waitSec for pedalboard idle
            while ({ done.not and: { SystemClock.seconds < deadline } }, {
                idle = (lps.pedalboard.tryPerform(\isBusy) ? false).not;
                if (idle) {
                    sendOnce.();
                    done = true;
                };
                if (done.not) { stepSec.wait };
            });

            // If not idle by deadline, retry a couple of times
            if (done.not) {
                attempt = 0;
                while ({ attempt < maxAttempts }, {
                    sendOnce.();
                    attempt = attempt + 1;
                    0.3.wait;
                });
            };
        });

        runner.play(AppClock);
    };
};
)