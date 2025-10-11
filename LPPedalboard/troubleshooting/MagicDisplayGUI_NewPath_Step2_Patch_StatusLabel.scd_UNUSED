// MagicDisplayGUI_NewPath_Step2_Patch_StatusLabel.scd
// v0.2.3
// MD timestamp: 2025-09-25

/* Purpose
   - Add a status label showing seconds since last level message ('rx age').
   - Helps confirm receiver is live.

   Style
   - var-first inside function bodies; no non-local returns (^).
*/

(
if (~mdGui_window.notNil) {
    var content, statusLabel;

    content = ~mdGui_window.view;

    statusLabel = StaticText(content, Rect(200, 120, 180, 18));
    statusLabel.string = "rx age: —";
    statusLabel.stringColor = Color.gray(0.85);
    statusLabel.background = Color.clear;
    statusLabel.align = \left;

    ~mdGui_status = statusLabel;

    // start an AppClock updater (store it so we can stop later)
    ~mdGui_statusTicker = Routine({
        var running, age, lastAt;

        running = true;
        while { running } {
            lastAt = if (~md_lastLevelAt.notNil) { ~md_lastLevelAt } { 0.0 };
            age = (Main.elapsedTime - lastAt).max(0.0).round(0.01);

            if (~mdGui_status.notNil) {
                ~mdGui_status.string = "rx age: " ++ age.asString ++ " s";
            };

            0.2.yield;
            running = (~mdGui_window.notNil);
        };
    }).play(AppClock);

    "Status label installed.".postln;
} {
    "Open the MagicDisplayGUI window first, then run this patch.".postln;
};
)
