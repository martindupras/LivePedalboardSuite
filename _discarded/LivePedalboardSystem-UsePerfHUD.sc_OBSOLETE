// LivePedalboardSystem-UsePerfHUD.sc
// v0.1.7
// MD 2025-09-26 15:38 BST

/* Purpose / Style
   PerfHUD v0.5.4 bring-up + robust meters (listener + stable taps).
   - var-first; descriptive lowercase; AppClock-only; no server.sync.
*/

+ LivePedalboardSystem {

    bringUpMagicDisplayGUI {
        var baseTroubleshooting, perfHudPath, perfExists, windowsList, pickedWindow;

        baseTroubleshooting = (Platform.userExtensionDir
            ++ "/LivePedalboardSuite/MagicPedalboard/troubleshooting").standardizePath;
        perfHudPath = (baseTroubleshooting
            ++ "/MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.4.scd").standardizePath;
        perfExists = File.exists(perfHudPath);

        this.closeExistingMagicDisplayWindows;

        if(perfExists) { perfHudPath.load } { statusDisplay = MagicDisplayGUI_GridDemo.new };

        // sources/sinks
        Server.default.bind({
            if(Ndef(\testmelody).source.isNil) {
                Ndef(\testmelody, {
                    var trig, freq, env, pan, scale, indexSel;
                    trig = Impulse.kr(2.2);
                    scale = [60, 62, 64, 67, 69];
                    indexSel = Demand.kr(trig, 0, Dwhite(0, scale.size, inf));
                    freq = Select.kr(indexSel, scale).midicps;
                    env = Decay2.kr(trig, 0.01, 0.40);
                    pan = LFNoise1.kr(0.3).range(-0.7, 0.7);
                    Pan2.ar(SinOsc.ar(freq) * env * 0.2, pan)
                });
            };
            Ndef(\testmelody).ar(2);
            if(Ndef(\ts0).source.isNil) { Ndef(\ts0, { Silent.ar(2) }) };
            Ndef(\ts0).ar(2);
            Ndef(\chainA).ar(2);
            Ndef(\chainB).ar(2);
        });
        "[LPS] sources/sinks ensured.".postln;

        // /md/levels listener (HUD-side)
        ~md_levelsById   = ~md_levelsById   ? IdentityDictionary.new;
        ~md_lastMsgStamp = ~md_lastMsgStamp ? SystemClock.seconds.asFloat;

        if(OSCdef.all.at(\md_levels_hud).notNil) { OSCdef.all.at(\md_levels_hud).free };
        OSCdef(\md_levels_hud, { arg msg;
            var replyId, leftVal, rightVal;
            if(msg.size >= 5) {
                replyId  = msg[2];
                leftVal  = msg[3].asFloat.clip(0, 1);
                rightVal = msg[4].asFloat.clip(0, 1);
                ~md_levelsById.put(replyId, [leftVal, rightVal]);
                ~md_lastMsgStamp = SystemClock.seconds.asFloat;
            };
            nil
        }, "/md/levels", recvPort: NetAddr.langPort);
        "[HUD] /md/levels listener installed (key=md_levels_hud)".postln;

        // Inline taps (visual scale)
        this.installStableMeters;
        "[LPS] inline taps armed (visual scale, A=2001, B=2002, T=1001).".postln;
//NEW
		this.installGuiMeters;  // installs isolated GUI taps -> /md/levels_gui

        // Front window & return
        windowsList = Window.allWindows;
        pickedWindow = windowsList.detect({ arg w;
            var titleString = w.tryPerform(\name);
            titleString.notNil and: { titleString.asString.beginsWith("MagicDisplayGUI") }
        });
        if(pickedWindow.notNil) { pickedWindow.front };
        pickedWindow
    }
}
