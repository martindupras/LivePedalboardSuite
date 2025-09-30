// PERFHUD_InlineTaps_On_ChainAB.scd
// v0.1.0
// MD 2025-09-29 15:26 BST

(
/* Purpose
   - Replace bus-based bridge (silent because no buses exist) with inline taps on Ndef(\chainA/\chainB).
   - Send linear amplitudes for PerfHUD via '/ampA' and '/ampB' (2 values each, L/R).
   - Also send dB readings via '/md/levels_db' with replyIDs A=2001, B=2002 for console sanity.
Style
   - var-first; descriptive lowercase variable names; Server.default.bind for server ops; AppClock for UI only.
   - No server.sync; no non-local returns; idempotent (re-running replaces the taps).
*/

var freeBusBridgeIfPresent, installInlineTaps, installDbSniffer, printLinesRemaining;
var attackSeconds, releaseSeconds, updateRateHz, minLinearFloor;
var oscKeyDb;

attackSeconds   = 0.01;
releaseSeconds  = 0.20;
updateRateHz    = 24;
minLinearFloor  = 1e-7;
printLinesRemaining = 6;
oscKeyDb = \perfHud_db_sniff;

// 1) Free the bus-bridge synth (if any), to avoid double feeds
freeBusBridgeIfPresent = {
    if(~md_levelsSynth.notNil) {
        ~md_levelsSynth.free;
        ~md_levelsSynth = nil;
        "99: Freed md_levels4_from_busses (bus bridge) — switching to inline taps.".postln;
    };
};

// 2) Install inline taps on chainA and chainB
installInlineTaps = {
    Server.default.bind({
        // chainA → '/ampA' (linear pair) and '/md/levels_db' (dB; replyID=2001)
        Ndef(\chainA).filter(\perfHudTapA, { arg inputSignal;
            var localSignal, pairArray, linearLeft, linearRight, linearPair, dbLeft, dbRight, updateTrigger;
            // normalize to a stereo pair (duplicate if mono)
            localSignal = inputSignal;
            pairArray = localSignal.asArray;
            if(pairArray.size < 2) { pairArray = [pairArray[0], pairArray[0]] };

            linearLeft  = Amplitude.kr(pairArray[0], attackSeconds, releaseSeconds).clip(0.0, 1.0);
            linearRight = Amplitude.kr(pairArray[1], attackSeconds, releaseSeconds).clip(0.0, 1.0);
            linearPair  = [linearLeft, linearRight];

            dbLeft  = (max(linearLeft,  minLinearFloor)).log10 * 20.0;
            dbRight = (max(linearRight, minLinearFloor)).log10 * 20.0;

            updateTrigger = Impulse.kr(updateRateHz);

            // For PerfHUD legacy listeners:
            SendReply.kr(updateTrigger, '/ampA', linearPair);

            // For console / optional HUD consumers:
            SendReply.kr(updateTrigger, '/md/levels_db', [dbLeft, dbRight], 2001);

            // return audio unchanged
            localSignal
        });

        // chainB → '/ampB' (linear pair) and '/md/levels_db' (dB; replyID=2002)
        Ndef(\chainB).filter(\perfHudTapB, { arg inputSignal;
            var localSignal, pairArray, linearLeft, linearRight, linearPair, dbLeft, dbRight, updateTrigger;
            localSignal = inputSignal;
            pairArray = localSignal.asArray;
            if(pairArray.size < 2) { pairArray = [pairArray[0], pairArray[0]] };

            linearLeft  = Amplitude.kr(pairArray[0], attackSeconds, releaseSeconds).clip(0.0, 1.0);
            linearRight = Amplitude.kr(pairArray[1], attackSeconds, releaseSeconds).clip(0.0, 1.0);
            linearPair  = [linearLeft, linearRight];

            dbLeft  = (max(linearLeft,  minLinearFloor)).log10 * 20.0;
            dbRight = (max(linearRight, minLinearFloor)).log10 * 20.0;

            updateTrigger = Impulse.kr(updateRateHz);

            // For PerfHUD legacy listeners:
            SendReply.kr(updateTrigger, '/ampB', linearPair);

            // For console / optional HUD consumers:
            SendReply.kr(updateTrigger, '/md/levels_db', [dbLeft, dbRight], 2002);

            // return audio unchanged
            localSignal
        });
    });

    "99: Inline taps installed on chainA/chainB → '/ampA' & '/ampB' (+ dB on '/md/levels_db').".postln;
};

// 3) Short-lived dB console sniffer (6 lines total), then auto-free
installDbSniffer = {
    // clean any previous instance
    if(OSCdef(oscKeyDb).notNil) { OSCdef(oscKeyDb).free };

    OSCdef(oscKeyDb, { arg message;
        var replyId, dbLeft, dbRight, labelText;
        if(message.size >= 5) {
            replyId = message[2];
            dbLeft  = message[3].round(0.1);
            dbRight = message[4].round(0.1);
            labelText = "[dB inline " ++ replyId.asString ++ "] L=" ++ dbLeft ++ " dB  R=" ++ dbRight ++ " dB";
            labelText.postln;

            printLinesRemaining = printLinesRemaining - 1;
            if(printLinesRemaining <= 0) {
                OSCdef(oscKeyDb).free;
                "[dB inline] sniff done.".postln;
            };
        };
    }, '/md/levels_db');
};

// Execute
freeBusBridgeIfPresent.();
installInlineTaps.();
installDbSniffer.();
)
