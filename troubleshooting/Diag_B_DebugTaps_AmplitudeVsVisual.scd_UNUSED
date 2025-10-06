// Diag_B_DebugTaps_AmplitudeVsVisual.scd
// v0.1.0
// MD 2025-09-26 17:45 BST

/* Purpose / Style
   Purpose: Add debug taps (non-intrusive) on chainA/chainB that SendReply both the raw amplitude and
            the mapped visual value to /md/levels_dbg with reply IDs 42001 (A) and 42002 (B).
            Then print one line/second with (ampLeft, ampRight) and (visLeft, visRight), so we can
            see if unity (1.0) appears at the Amplitude stage or in the mapping/transport.
   Style:   var-first; descriptive lowercase variable names (>=3 chars); Server.default.bind; no server.sync.
*/

(
// ---- 1) Install debug taps (server side, pass-through audio intact)
var install_debug_taps;

install_debug_taps = {
    Server.default.bind({
        var rate_hertz, floor_amp;
        rate_hertz = 24;
        floor_amp  = 1e-5;

        // chainA → replyID 42001
        Ndef(\chainA).filter(\mdDebugTapA, { arg in_sig;
            var input_pair, amp_left, amp_right, map_left, map_right, vis_left, vis_right;

            input_pair = in_sig.isArray.if({ in_sig }, { [in_sig, in_sig] });

            amp_left   = Amplitude.kr(input_pair[0], 0.01, 0.20).clip(floor_amp, 1.0);
            amp_right  = Amplitude.kr(input_pair[1], 0.01, 0.20).clip(floor_amp, 1.0);

            map_left   = LinExp.kr(amp_left,  floor_amp, 1.0, 0.0, 1.0).clip(0, 1);
            map_right  = LinExp.kr(amp_right, floor_amp, 1.0, 0.0, 1.0).clip(0, 1);

            vis_left   = LagUD.kr(map_left,  0.02, 0.12).clip(0, 1);
            vis_right  = LagUD.kr(map_right, 0.02, 0.12).clip(0, 1);

            // DO NOT overwrite vis_left/vis_right with CheckBadValues result;
            // we only call it for side-effect logging.
            CheckBadValues.kr(vis_left,  id: 0, post: 0);
            CheckBadValues.kr(vis_right, id: 0, post: 0);

            // Send both raw amplitude and final visual as 4 floats
            // payload: [ampLeft, ampRight, visLeft, visRight]
            SendReply.kr(Impulse.kr(rate_hertz), "/md/levels_dbg",
                [amp_left, amp_right, vis_left, vis_right], 42001);

            in_sig
        });

        // chainB → replyID 42002
        Ndef(\chainB).filter(\mdDebugTapB, { arg in_sig;
            var input_pair, amp_left, amp_right, map_left, map_right, vis_left, vis_right;

            input_pair = in_sig.isArray.if({ in_sig }, { [in_sig, in_sig] });

            amp_left   = Amplitude.kr(input_pair[0], 0.01, 0.20).clip(floor_amp, 1.0);
            amp_right  = Amplitude.kr(input_pair[1], 0.01, 0.20).clip(floor_amp, 1.0);

            map_left   = LinExp.kr(amp_left,  floor_amp, 1.0, 0.0, 1.0).clip(0, 1);
            map_right  = LinExp.kr(amp_right, floor_amp, 1.0, 0.0, 1.0).clip(0, 1);

            vis_left   = LagUD.kr(map_left,  0.02, 0.12).clip(0, 1);
            vis_right  = LagUD.kr(map_right, 0.02, 0.12).clip(0, 1);

            CheckBadValues.kr(vis_left,  id: 0, post: 0);
            CheckBadValues.kr(vis_right, id: 0, post: 0);

            SendReply.kr(Impulse.kr(rate_hertz), "/md/levels_dbg",
                [amp_left, amp_right, vis_left, vis_right], 42002);

            in_sig
        });
    });
    "MDDBG: debug taps installed (/md/levels_dbg; A=42001, B=42002).".postln;
};

install_debug_taps.();
nil
)

// ---- 2) Install compact, 1 Hz debug listener (language side; prints one line per second)
(
// Shared dictionary so we can read and format values
var dbg_values_by_id, dbg_listener_key, dbg_reporter_routine;

dbg_values_by_id = ~md_levels_dbg ? IdentityDictionary.new;
~md_levels_dbg = dbg_values_by_id;

// Listener
dbg_listener_key = \md_levels_dbg_sniffer;
if(OSCdef.all.at(dbg_listener_key).notNil) { OSCdef.all.at(dbg_listener_key).free };
OSCdef(dbg_listener_key, { arg osc_message;
    var reply_id, amp_left, amp_right, vis_left, vis_right;
    var valid_payload;

    valid_payload = (osc_message.size >= 7); // addr, timeTag, id, v0, v1, v2, v3 → size >= 7
    if(valid_payload) {
        reply_id  = osc_message[2];
        amp_left  = osc_message[3];
        amp_right = osc_message[4];
        vis_left  = osc_message[5];
        vis_right = osc_message[6];

        // Minimal guards
        amp_left  = (amp_left.isNumber  and: { amp_left .isNaN.not })  .if({ amp_left  .clip(0,1) }, { 0.0 });
        amp_right = (amp_right.isNumber and: { amp_right.isNaN.not })  .if({ amp_right .clip(0,1) }, { 0.0 });
        vis_left  = (vis_left.isNumber  and: { vis_left .isNaN.not })  .if({ vis_left  .clip(0,1) }, { 0.0 });
        vis_right = (vis_right.isNumber and: { vis_right.isNaN.not })  .if({ vis_right .clip(0,1) }, { 0.0 });

        dbg_values_by_id.put(reply_id, [amp_left, amp_right, vis_left, vis_right]);
    };
    nil
}, "/md/levels_dbg", recvPort: NetAddr.langPort);
"MDDBG: /md/levels_dbg sniffer installed.".postln;

// Reporter
if(~md_levels_dbg_reporter.notNil) { ~md_levels_dbg_reporter.stop };
~md_levels_dbg_reporter = Routine({
    var keep_running;
    keep_running = true;
    while({ keep_running }, {
        var a_vals, b_vals, text_a, text_b;
        a_vals = dbg_values_by_id.at(42001) ? [0,0,0,0];
        b_vals = dbg_values_by_id.at(42002) ? [0,0,0,0];

        text_a = "A amp=("
            ++ a_vals[0].round(0.01) ++ "," ++ a_vals[1].round(0.01)
            ++ ") vis=("
            ++ a_vals[2].round(0.01) ++ "," ++ a_vals[3].round(0.01) ++ ")";

        text_b = "B amp=("
            ++ b_vals[0].round(0.01) ++ "," ++ b_vals[1].round(0.01)
            ++ ") vis=("
            ++ b_vals[2].round(0.01) ++ "," ++ b_vals[3].round(0.01) ++ ")";

        ("MDDBG: " ++ text_a ++ "   " ++ text_b).postln;
        1.0.wait;
    });
}).play(AppClock);

nil
)
