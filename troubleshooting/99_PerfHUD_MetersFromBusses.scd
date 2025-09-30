// 99_PerfHUD_MetersFromBusses.scd
// v0.1.1
// MD 2025-09-29 15:22 BST
(
/* Purpose
   - Bridge two 2-ch AUDIO buses (A and B) into the PerfHUD UI via OSC:
       • '/md/levels_gui'  → linear amplitudes (0..1)  [A L, A R, B L, B R]
       • '/md/levels_db'   → dBFS values (≈ -inf..0)   [A L, A R, B L, B R]
       • '/ampA', '/ampB'  → linear pairs for legacy listeners
   - Provide optional test pattern (fixed values) to prove the UI is controllable.
   - Optionally print a few lines of dB to the console to validate input sanity.

Style
   - var-first everywhere; descriptive lowercase names; no single-letter locals.
   - Server.default.bind for server ops; AppClock for UI; no server.sync; no non-local returns.
*/

var busIndexA, busIndexB;
var attackSeconds, releaseSeconds, updateRateHz;
var useTestPattern, testValueAL, testValueAR, testValueBL, testValueBR;
var printDbLinesCount;

var installSynthDefinitions, startMeterBridge, nudgeHudOnce, installDbConsolePrinter;

// --- Configuration (edit these if needed) ------------------------------------
busIndexA        = 2001;        // your A-tap bus index (2 channels expected)
busIndexB        = 2002;        // your B-tap bus index (2 channels expected)
attackSeconds    = 0.01;        // Amplitude.kr attack time
releaseSeconds   = 0.20;        // Amplitude.kr release time
updateRateHz     = 24;          // OSC update rate for GUI

useTestPattern   = false;       // set true to drive meters with fixed values
testValueAL      = 0.25;        // A left (linear 0..1)
testValueAR      = 0.50;        // A right
testValueBL      = 0.75;        // B left
testValueBR      = 0.50;        // B right

printDbLinesCount = 6;          // number of dB lines to print to console (0 disables)

// --- Definitions --------------------------------------------------------------
installSynthDefinitions = {
    var synthAdder;

    synthAdder = {
        // Two-bus (stereo+stereo) → linear + dB, with optional test pattern
        SynthDef(\md_levels4_from_busses, {
            arg inBusA = 2001, inBusB = 2002, updatesPerSecond = 24,
                ampAttack = 0.01, ampRelease = 0.20,
                enableTestPattern = 0,
                patternAL = 0.25, patternAR = 0.50, patternBL = 0.75, patternBR = 0.50;

            var inputStereoA, inputStereoB;
            var ampLinearAL, ampLinearAR, ampLinearBL, ampLinearBR;
            var linearAL, linearAR, linearBL, linearBR;
            var dbAL, dbAR, dbBL, dbBR;
            var updateTrigger;
            var minLinearFloor;

            // Read 2 channels from each bus
            inputStereoA = In.ar(inBusA, 2);
            inputStereoB = In.ar(inBusB, 2);

            // Measure linear amplitude at control rate
            ampLinearAL = Amplitude.kr(inputStereoA[0], ampAttack, ampRelease).clip(0.0, 1.0);
            ampLinearAR = Amplitude.kr(inputStereoA[1], ampAttack, ampRelease).clip(0.0, 1.0);
            ampLinearBL = Amplitude.kr(inputStereoB[0], ampAttack, ampRelease).clip(0.0, 1.0);
            ampLinearBR = Amplitude.kr(inputStereoB[1], ampAttack, ampRelease).clip(0.0, 1.0);

            // Select measured vs. test pattern
            linearAL = Select.kr(enableTestPattern, [ampLinearAL, patternAL]);
            linearAR = Select.kr(enableTestPattern, [ampLinearAR, patternAR]);
            linearBL = Select.kr(enableTestPattern, [ampLinearBL, patternBL]);
            linearBR = Select.kr(enableTestPattern, [ampLinearBR, patternBR]);

            // Convert to dB (guard the floor to avoid -inf)
            minLinearFloor = 1e-7;
            dbAL = (max(linearAL, minLinearFloor)).log10 * 20.0;
            dbAR = (max(linearAR, minLinearFloor)).log10 * 20.0;
            dbBL = (max(linearBL, minLinearFloor)).log10 * 20.0;
            dbBR = (max(linearBR, minLinearFloor)).log10 * 20.0;

            // Tick and send
            updateTrigger = Impulse.kr(updatesPerSecond);

            // Linear for GUI
            SendReply.kr(updateTrigger, '/md/levels_gui', [linearAL, linearAR, linearBL, linearBR]);

            // dB for console or dB-aware GUIs
            SendReply.kr(updateTrigger, '/md/levels_db',  [dbAL, dbAR, dbBL, dbBR]);

            // Legacy: per-chain linear pairs
            SendReply.kr(updateTrigger, '/ampA', [linearAL, linearAR]);
            SendReply.kr(updateTrigger, '/ampB', [linearBL, linearBR]);
        }).add;
    };

    Server.default.bind(synthAdder);
    "99: SynthDef \\md_levels4_from_busses installed.".postln;
};

startMeterBridge = {
    var freeOld, startNew;

    freeOld = {
        if(~md_levelsSynth.notNil) {
            ~md_levelsSynth.free;
            ~md_levelsSynth = nil;
        };
    };

    startNew = {
        Server.default.bind({
            ~md_levelsSynth = Synth(
                \md_levels4_from_busses,
                [
                    \inBusA,          busIndexA,
                    \inBusB,          busIndexB,
                    \updatesPerSecond, updateRateHz,
                    \ampAttack,        attackSeconds,
                    \ampRelease,       releaseSeconds,
                    \enableTestPattern, (useTestPattern.if({ 1 }, { 0 })),
                    \patternAL,        testValueAL,
                    \patternAR,        testValueAR,
                    \patternBL,        testValueBL,
                    \patternBR,        testValueBR
                ]
            );
        });
        ("99: Started md_levels4_from_busses on A=" ++ busIndexA
            ++ "  B=" ++ busIndexB
            ++ "  testPattern=" ++ useTestPattern).postln;
    };

    freeOld.();
    startNew.();
};

nudgeHudOnce = {
    var doIt;

    doIt = {
        if(~gui.notNil and: { ~gui.respondsTo(\highlightCurrentColumn) }) {
            ~gui.highlightCurrentColumn(\chainA);
        };
        if(~gui.notNil and: { ~gui.respondsTo(\showExpectation) }) {
            ~gui.showExpectation("HUD: meters bridged from A/B buses", 0);
        };
        nil
    };

    AppClock.sched(0.10, doIt);
};

installDbConsolePrinter = {
    var oscKeyName, linesRemaining;

    oscKeyName     = \md_levels_db_console_printer;
    linesRemaining = printDbLinesCount.max(0).asInteger;

    // Optional: print a few dB lines then auto-stop
    if(linesRemaining > 0) {
        OSCdef(oscKeyName, { arg message;
            var dbLeftA, dbRightA, dbLeftB, dbRightB, lineText;

            if(message.size >= 5) {
                // ['/md/levels_db', nodeID, replyID, dB_AL, dB_AR, dB_BL, dB_BR] (nodeID/replyID vary by build)
                dbLeftA   = message[3].round(0.1);
                dbRightA  = message[4].round(0.1);
                dbLeftB   = message[5].round(0.1);
                dbRightB  = message[6].round(0.1);

                lineText = "[dB]  A: L=" ++ dbLeftA  ++ " dB  R=" ++ dbRightA
                         ++ "   |   B: L=" ++ dbLeftB ++ " dB  R=" ++ dbRightB;
                lineText.postln;

                linesRemaining = linesRemaining - 1;
                if(linesRemaining <= 0) {
                    OSCdef(oscKeyName).free;
                    "[dB] console printer finished.".postln;
                };
            };
        }, '/md/levels_db');
    };
};

// --- Run sequence -------------------------------------------------------------
installSynthDefinitions.();
installDbConsolePrinter.();               // prints a few lines if printDbLinesCount > 0
AppClock.sched(0.05, {
    startMeterBridge.();
    nudgeHudOnce.();
    nil
});
)
