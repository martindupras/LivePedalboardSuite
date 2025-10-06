// Fix_Taps_CheckBadValues_SideEffect.scd
// v0.1.0
// MD 2025-09-26 17:35 BST

/* Purpose / Style
   Purpose: Reinstall /md/levels taps for A/B so that CheckBadValues.kr is side-effect only
            (do not overwrite the visual signals). This should remove the constant 1.0 issue.
   Style:   var-first; descriptive lowercase variable names; Server.default.bind; no server.sync.
*/

(
var reinstallOnce;

reinstallOnce = {
    Server.default.bind({
        var rate_hertz, floor_amp;
        rate_hertz = 24;
        floor_amp  = 1e-5;

        // ---- CHAIN A → replyID 2001
        Ndef(\chainA).filter(\mdVisTapA, { arg in_sig;
            var input_pair, amp_left, amp_right, map_left, map_right, vis_left, vis_right;

            input_pair = in_sig.isArray.if({ in_sig }, { [in_sig, in_sig] });
            amp_left   = Amplitude.kr(input_pair[0], 0.01, 0.20).clip(floor_amp, 1.0);
            amp_right  = Amplitude.kr(input_pair[1], 0.01, 0.20).clip(floor_amp, 1.0);

            // Log-like visual map then gentle smoothing; keep 0..1
            map_left   = LinExp.kr(amp_left,  floor_amp, 1.0, 0.0, 1.0).clip(0, 1);
            map_right  = LinExp.kr(amp_right, floor_amp, 1.0, 0.0, 1.0).clip(0, 1);
            vis_left   = LagUD.kr(map_left,  0.02, 0.12).clip(0, 1);
            vis_right  = LagUD.kr(map_right, 0.02, 0.12).clip(0, 1);

            // Side-effect diagnostics only (do NOT assign result)
            CheckBadValues.kr(vis_left,  id: 0, post: 0);
            CheckBadValues.kr(vis_right, id: 0, post: 0);

            SendReply.kr(Impulse.kr(rate_hertz), "/md/levels", [vis_left, vis_right], 2001);
            in_sig  // pass-through audio
        });

        // ---- CHAIN B → replyID 2002
        Ndef(\chainB).filter(\mdVisTapB, { arg in_sig;
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

            SendReply.kr(Impulse.kr(rate_hertz), "/md/levels", [vis_left, vis_right], 2002);
            in_sig
        });
    });
    "MDTAPS: reinstalled /md/levels taps (A=2001, B=2002) with side-effect checks only.".postln;
};

reinstallOnce.();
nil
)
