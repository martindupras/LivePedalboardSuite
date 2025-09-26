// LivePedalboardSystem-Taps_Stable.sc
// v0.1.2 (sanitised + smoothed + boosted)
// MD 2025-09-26 15:58 BST

/* Purpose
   Install stable, visual-scale taps under unique keys, with NaN/Inf sanitised,
   light smoothing, and a more sensitive floor so meters are visibly responsive.
   - Unique keys: \mdVisTapA, \mdVisTapB, \mdVisTapT (won’t clash with re-installers).
   - Re-applies 3x (0.0s, 0.5s, 1.0s) to outlast late bindings.
   - Pass-through audio: always return 'in'.
   Style: var-first; descriptive lowercase; AppClock-only; no server.sync; no non-local '^'.
*/

+ LivePedalboardSystem {

    installStableMeters {
        var rateHz, rateClamped, applyOnce, passIndex, passCount;
        var atk, rel, floorAmp;

        rateHz     = 24;        // slightly faster UI feel
        rateClamped = rateHz.asInteger.clip(1, 60);
        passIndex  = 0; passCount = 3;

        // meter behaviour
        atk = 0.01;             // Amplitude attack
        rel = 0.20;             // Amplitude release
        floorAmp = 1e-5;        // more sensitive floor than 1e-6

        applyOnce = {
            Server.default.bind({

                // ----- CHAIN A -> replyID 2001 -----
                Ndef(\chainA).filter(\mdVisTapA, { arg in;
                    var sig, ampL, ampR, visL, visR;
                    sig  = in.isArray.if({ in }, { [in, in] });

                    ampL = Amplitude.kr(sig[0], atk, rel).clip(floorAmp, 1.0);
                    ampR = Amplitude.kr(sig[1], atk, rel).clip(floorAmp, 1.0);

                    // Log-like visual map + light smoothing (no audio change)
                    visL = LinExp.kr(ampL, floorAmp, 1.0, 0.0, 1.0).clip(0, 1);
                    visR = LinExp.kr(ampR, floorAmp, 1.0, 0.0, 1.0).clip(0, 1);
                    visL = LagUD.kr(visL, 0.02, 0.12).clip(0, 1);
                    visR = LagUD.kr(visR, 0.02, 0.12).clip(0, 1);

                    // Sanitize: replace any NaN/Inf with 0 (quietly)
                    visL = CheckBadValues.kr(visL, id: 0, post: 0);
                    visR = CheckBadValues.kr(visR, id: 0, post: 0);

                    SendReply.kr(Impulse.kr(rateClamped), "/md/levels", [visL, visR], 2001);
                    in
                });

                // ----- CHAIN B -> replyID 2002 -----
                Ndef(\chainB).filter(\mdVisTapB, { arg in;
                    var sig, ampL, ampR, visL, visR;
                    sig  = in.isArray.if({ in }, { [in, in] });

                    ampL = Amplitude.kr(sig[0], atk, rel).clip(floorAmp, 1.0);
                    ampR = Amplitude.kr(sig[1], atk, rel).clip(floorAmp, 1.0);

                    visL = LinExp.kr(ampL, floorAmp, 1.0, 0.0, 1.0).clip(0, 1);
                    visR = LinExp.kr(ampR, floorAmp, 1.0, 0.0, 1.0).clip(0, 1);
                    visL = LagUD.kr(visL, 0.02, 0.12).clip(0, 1);
                    visR = LagUD.kr(visR, 0.02, 0.12).clip(0, 1);

                    visL = CheckBadValues.kr(visL, id: 0, post: 0);
                    visR = CheckBadValues.kr(visR, id: 0, post: 0);

                    SendReply.kr(Impulse.kr(rateClamped), "/md/levels", [visL, visR], 2002);
                    in
                });

                // ----- TEST PROBE -> replyID 1001 -----
                Ndef(\testmelody).filter(\mdVisTapT, { arg in;
                    var sig, ampL, ampR, visL, visR;
                    sig  = in.isArray.if({ in }, { [in, in] });

                    ampL = Amplitude.kr(sig[0], atk, rel).clip(floorAmp, 1.0);
                    ampR = Amplitude.kr(sig[1], atk, rel).clip(floorAmp, 1.0);

                    visL = LinExp.kr(ampL, floorAmp, 1.0, 0.0, 1.0).clip(0, 1);
                    visR = LinExp.kr(ampR, floorAmp, 1.0, 0.0, 1.0).clip(0, 1);
                    visL = LagUD.kr(visL, 0.02, 0.12).clip(0, 1);
                    visR = LagUD.kr(visR, 0.02, 0.12).clip(0, 1);

                    visL = CheckBadValues.kr(visL, id: 0, post: 0);
                    visR = CheckBadValues.kr(visR, id: 0, post: 0);

                    SendReply.kr(Impulse.kr(rateClamped), "/md/levels", [visL, visR], 1001);
                    in
                });

            });
        };

        // Apply now, then again at 0.5s and 1.0s to survive late re-binds
        AppClock.sched(0.00, { applyOnce.(); passIndex = passIndex + 1; 0.50 });
        AppClock.sched(0.50, { applyOnce.(); passIndex = passIndex + 1; 0.50 });
        AppClock.sched(1.00, { applyOnce.(); "[LPS] stable taps active (sanitised+smoothed).".postln; nil });

        this
    }

}
