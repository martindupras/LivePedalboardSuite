// Switch_Send_Quiet_Retry3.scd
// v0.1.0
// MD 20251006-1756

/*
Purpose
- Flip ACTIVE by sending "/switch" via the installed bridge.
- Quiet (master-mute stays on); no CommandTree navigation used.
- Sends once immediately, then twice more at 0.35s intervals (to miss a short "busy" window).
Style
- var-first; no server.sync; AppClock timing; no non-local returns.
*/

(
var lps, cm, sendOnce, scheduleRetries, okBridge;

lps = ~lps;

if (lps.isNil) {
    "[Switch_Retry3] ~lps is nil. Run your starter first.".warn;
} {
    cm = lps.commandManager;

    okBridge = (cm.notNil) and: { cm.queueExportCallback.notNil };

    if (okBridge.not) {
        "[Switch_Retry3] Bridge not installed (queueExportCallback is nil). Run your starter again.".warn;
    } {
        sendOnce = {
            cm.queueExportCallback.("/switch");
            "[Switch_Retry3] sent /switch".postln;
        };

        scheduleRetries = {
            AppClock.sched(0.00, { sendOnce.(); nil });
            AppClock.sched(0.35, { sendOnce.(); nil });
            AppClock.sched(0.70, { sendOnce.(); nil });
        };

        scheduleRetries.();
    };
};
)