// Diag_2_LevelsSniffer_FIXED.scd
// v0.1.2
// MD 2025-09-26 17:25 BST

/* Purpose / Style
   Purpose: Confirm that /md/levels messages arrive from stable taps (A=2001, B=2002).
            Prints compact values every second.
   Style:   var-first; descriptive lowercase names; AppClock; no server.sync; no single-letter variable names.
*/

(
var ensure_stable_taps, install_listener, start_reporter;
var values_by_id, last_stamp_seconds, reporter_routine;

// Share dictionary with any overlays; create if missing
values_by_id = ~md_levelsById ? IdentityDictionary.new;
~md_levelsById = values_by_id;
last_stamp_seconds = SystemClock.seconds.asFloat;

// Reinstall sanitised/smoothed taps to /md/levels with IDs 2001/2002
ensure_stable_taps = {
    if(~system.notNil) {
        ~system.installStableMeters;   // known-good installer in your codebase
        "MD2: stable taps reinstalled (IDs 2001/2002).".postln;
    } {
        "MD2: ~system is nil; cannot reinstall taps.".warn;
    };
};

// Listener updating ~md_levelsById (guard NaN and non-numbers; clip to [0,1])
install_listener = {
    var osc_key;
    osc_key = \md_levels_sniffer_fixed;
    if(OSCdef.all.at(osc_key).notNil) { OSCdef.all.at(osc_key).free };
    OSCdef(osc_key, { arg osc_message;
        var reply_id, left_value, right_value, safe_left, safe_right, now_seconds;
        var left_is_bad, right_is_bad;

        if(osc_message.size >= 5) {
            reply_id   = osc_message[2];
            left_value  = osc_message[3];
            right_value = osc_message[4];

            left_is_bad  = (left_value.isNumber.not)  or: { left_value.isNaN };
            right_is_bad = (right_value.isNumber.not) or: { right_value.isNaN };

            safe_left  = left_is_bad.if({ 0.0 }, { left_value.clip(0, 1) });
            safe_right = right_is_bad.if({ 0.0 }, { right_value.clip(0, 1) });

            values_by_id.put(reply_id, [safe_left, safe_right]);
            now_seconds = SystemClock.seconds.asFloat;
            last_stamp_seconds = now_seconds;
        };
        nil
    }, "/md/levels", recvPort: NetAddr.langPort);
    "MD2: /md/levels sniffer installed.".postln;
};

// 1 Hz reporter
start_reporter = {
    if(reporter_routine.notNil) { reporter_routine.stop };
    reporter_routine = Routine({
        var keep_running;
        keep_running = true;
        while({ keep_running }, {
            var pair_a, pair_b, text_a, text_b;
            pair_a = values_by_id.at(2001) ? [0, 0];
            pair_b = values_by_id.at(2002) ? [0, 0];
            text_a = "A(L,R)=(" ++ pair_a[0].round(0.01) ++ "," ++ pair_a[1].round(0.01) ++ ")";
            text_b = "B(L,R)=(" ++ pair_b[0].round(0.01) ++ "," ++ pair_b[1].round(0.01) ++ ")";
            ("MD2: " ++ text_a ++ "  " ++ text_b).postln;
            1.0.wait;
        });
    }).play(AppClock);
};

ensure_stable_taps.();
install_listener.();
start_reporter.();
nil
)
