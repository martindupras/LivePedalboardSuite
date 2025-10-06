// LivePedalboardSystem-Taps_Isolated.sc
// v0.1.0 (isolated GUI taps: /md/levels_gui)
// MD 2025-09-26 16:10 BST

/* Purpose
   Install stable, sanitised, smoothed, log-like visual taps that send to a
   dedicated address "/md/levels_gui" with unique reply IDs:
     GA=32001, GB=32002, GT=31001
   - Unique filter keys: \mdGuiTapA, \mdGuiTapB, \mdGuiTapT (won’t clash).
   - Re-applies 3× (0.0s, 0.5s, 1.0s) to survive late re-binds.
   - Pass-through audio: always return 'in'.
   Style: var-first; descriptive lowercase; AppClock-only; no server.sync.
*/

+ LivePedalboardSystem {

    installGuiMeters {
        var rateHz, rateClamped, applyOnce, passIndex, passCount;
        var atk, rel, floorAmp, oscPath;
        var idA, idB, idT;

        rateHz      = 24;
        rateClamped = rateHz.asInteger.clip(1, 60);
        atk = 0.01; rel = 0.20; floorAmp = 1e-5;
        oscPath = "/md/levels_gui";
        idA = 32001; idB = 32002; idT = 31001;

        passIndex = 0; passCount = 3;

        applyOnce = {
            Server.default.bind({

                // ----- A -----
                Ndef(\chainA).filter(\mdGuiTapA, { arg in;
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

                    SendReply.kr(Impulse.kr(rateClamped), oscPath, [visL, visR], idA);
                    in
                });

                // ----- B -----
                Ndef(\chainB).filter(\mdGuiTapB, { arg in;
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

                    SendReply.kr(Impulse.kr(rateClamped), oscPath, [visL, visR], idB);
                    in
                });

                // ----- Test probe -----
                Ndef(\testmelody).filter(\mdGuiTapT, { arg in;
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

                    SendReply.kr(Impulse.kr(rateClamped), oscPath, [visL, visR], idT);
                    in
                });

            });
        };

        // Apply now, then again at 0.5s and 1.0s (survive late re-binds)
        AppClock.sched(0.00, { applyOnce.(); 0.50 });
        AppClock.sched(0.50, { applyOnce.(); 0.50 });
        AppClock.sched(1.00, { applyOnce.(); "[LPS] GUI taps active (/md/levels_gui).".postln; nil });

        this
    }

}
