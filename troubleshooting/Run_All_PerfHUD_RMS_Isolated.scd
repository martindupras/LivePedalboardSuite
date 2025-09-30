// Run_All_PerfHUD_RMS_Isolated.scd
// v0.1.0
// MD 2025-09-29 19:40 BST

/* Purpose
   One-shot bring-up from a clean SC restart:
     1) 00_Reset_KnownClean_State.scd
     2) 01b_StartHere_NoReboot.scd
     3) 02S_AssertStereo_ChainAB_and_Retap_SAFE.scd
     4) 02D_TestSource_CenteredStereo_Pulsed.scd
     5) RMS_IsolatedHUD (new window): reads ends of chainA/chainB, RMS.ar(sig,500) → dB → meters

Style
   - var-first; descriptive lowercase names; AppClock for sequencing/GUI; Server.default.bind for server ops.
   - No server.sync; no non-local returns. Returns '-> a Window' (the RMS window) at the end.
*/

(
var // config (paths and small timings)
    baseDir, fReset, fStartHere, fAssertStereo, fTestSource,
    smallPause, mediumPause, longPause,

    // helpers
    ensureBaseDir, executeFileOnce, scheduleSequence,

    // rms window block (self-contained)
    buildRmsIsolatedHud, // returns a Window
    finalWindow;

// --- configuration (adjust only if your file names differ) -------------------
smallPause  = 0.25;   // seconds between immediate steps
mediumPause = 0.60;   // seconds to allow bring-up to tick
longPause   = 1.00;   // seconds for heavier steps

// Derive the troubleshooting/ folder by default (assumes this file is saved there)
ensureBaseDir = {
    // If this script is saved as a file, we can use nowExecutingPath; otherwise ask user to set.
    var fromFile = thisProcess.nowExecutingPath;
    if(fromFile.notNil) {
        baseDir = PathName(fromFile).parentPath;  // should end with '/'
    }{
        // Fallback: try to guess a 'troubleshooting' folder relative to current documents dir.
        // If this fails on your setup, please SAVE this file in the 'troubleshooting/' folder
        // and re-run so nowExecutingPath is available.
        baseDir = PathName(thisProcess.platform.userAppSupportDir).parentPath ++ "troubleshooting";
        "[RunAll] Warning: nowExecutingPath is nil; guessing baseDir: ".post; baseDir.postln;
    };

    // File names expected to be in baseDir
    fReset       = baseDir ++ "00_Reset_KnownClean_State.scd";
    fStartHere   = baseDir ++ "01b_StartHere_NoReboot.scd";
    fAssertStereo= baseDir ++ "02S_AssertStereo_ChainAB_and_Retap_SAFE.scd";
    fTestSource  = baseDir ++ "02D_TestSource_CenteredStereo_Pulsed.scd";
};

// Execute a file if it exists; prints a readable status line
executeFileOnce = { arg absolutePathString, labelString;
    var pathOk;
    pathOk = File.exists(absolutePathString);
    if(pathOk.not) {
        ("[RunAll] ⚠️ Missing file: " ++ absolutePathString).warn;
    }{
        ("[RunAll] === " ++ labelString ++ " ===").postln;
        thisProcess.interpreter.executeFile(absolutePathString);
    };
    pathOk
};

// Self-contained RMS window that reads ends of chainA/chainB, computes RMS.dB, displays 4 meters
buildRmsIsolatedHud = {
    var defaultFloorDb, defaultTopDb, updateRateHz;
    var rmsWindow, labelTitle, labelDbA, labelDbB;
    var meterAL, meterAR, meterBL, meterBR, updateRoutine;
    var currentDbAL, currentDbAR, currentDbBL, currentDbBR;
    var installSynthDef, startRmsSynthAtTail, stopRmsSynth;
    var oscKeyName, installRmsListener;
    var discoverBussesAndStart, getProxyBusInfo;
    var chainAInfo, chainBInfo, busIndexA, busIndexB, triesLeft;

    defaultFloorDb = -72.0;
    defaultTopDb   =   0.0;   // set to +3.0 for extra visual headroom at full scale
    updateRateHz   =  15;

    // allow live tuning (optional)
    ~rms_isolated_floor_db = ~rms_isolated_floor_db ? defaultFloorDb;
    ~rms_isolated_top_db   = ~rms_isolated_top_db   ? defaultTopDb;

    rmsWindow = Window("RMS_IsolatedHUD — chain ends (A/B) — RMS dB", Rect(100, 100, 440, 210)).front;

    labelTitle = StaticText(rmsWindow, Rect(10, 8, 420, 18))
        .string_("RMS @ chain ends  (RMS.ar(sig, 500), dBFS)")
        .font_(Font("Helvetica", 13));

    meterAL = LevelIndicator(rmsWindow, Rect( 40, 40, 60, 110)).drawsPeak_(false).warning_(0.95).critical_(1.0).value_(0.0);
    meterAR = LevelIndicator(rmsWindow, Rect(120, 40, 60, 110)).drawsPeak_(false).warning_(0.95).critical_(1.0).value_(0.0);
    meterBL = LevelIndicator(rmsWindow, Rect(230, 40, 60, 110)).drawsPeak_(false).warning_(0.95).critical_(1.0).value_(0.0);
    meterBR = LevelIndicator(rmsWindow, Rect(310, 40, 60, 110)).drawsPeak_(false).warning_(0.95).critical_(1.0).value_(0.0);

    StaticText(rmsWindow, Rect( 40, 155, 60, 16)).string_("A L").align_(\center);
    StaticText(rmsWindow, Rect(120, 155, 60, 16)).string_("A R").align_(\center);
    StaticText(rmsWindow, Rect(230, 155, 60, 16)).string_("B L").align_(\center);
    StaticText(rmsWindow, Rect(310, 155, 60, 16)).string_("B R").align_(\center);

    labelDbA = StaticText(rmsWindow, Rect(10, 175, 210, 18)).string_("A: L=-∞  R=-∞");
    labelDbB = StaticText(rmsWindow, Rect(220, 175, 210, 18)).string_("B: L=-∞  R=-∞");

    currentDbAL = -140.0; currentDbAR = -140.0;
    currentDbBL = -140.0; currentDbBR = -140.0;

    installSynthDef = {
        Server.default.bind({
            SynthDef(\md_rms_isolated_from_busses, {
                arg inBusA = 0, inBusB = 0, fps = 15;
                var sigA, sigB, aLeft, aRight, bLeft, bRight;
                var rmsAL, rmsAR, rmsBL, rmsBR;
                var dbAL, dbAR, dbBL, dbBR;
                var tick, minLinear;

                sigA = In.ar(inBusA, 2);
                sigB = In.ar(inBusB, 2);

                aLeft  = sigA[0];
                aRight = (sigA.size > 1).if({ sigA[1] }, { sigA[0] });
                bLeft  = sigB[0];
                bRight = (sigB.size > 1).if({ sigB[1] }, { sigB[0] });

                // RMS per channel with 500 Hz smoothing (requested)
                rmsAL = RMS.ar(aLeft,  500);
                rmsAR = RMS.ar(aRight, 500);
                rmsBL = RMS.ar(bLeft,  500);
                rmsBR = RMS.ar(bRight, 500);

                // dBFS with guard
                minLinear = 1e-9;
                dbAL = (max(rmsAL, minLinear)).log10 * 20.0;
                dbAR = (max(rmsAR, minLinear)).log10 * 20.0;
                dbBL = (max(rmsBL, minLinear)).log10 * 20.0;
                dbBR = (max(rmsBR, minLinear)).log10 * 20.0;

                tick = Impulse.kr(fps);
                SendReply.kr(tick, "/md/rms_isolated_dB", [dbAL, dbAR, dbBL, dbBR]);  // private path for this window
            }).add;
        });
        "[RunAll/RMS] SynthDef \\md_rms_isolated_from_busses installed.".postln;
    };

    stopRmsSynth = {
        if(~rms_isolated_synth.notNil) {
            ~rms_isolated_synth.free; ~rms_isolated_synth = nil;
            "[RunAll/RMS] previous synth stopped.".postln;
        };
    };

    // IMPORTANT: start at TAIL so we read busses *after* chains write to them
    startRmsSynthAtTail = { arg busIndexForA, busIndexForB;
        AppClock.sched(0.20, {
            Server.default.bind({
                ~rms_isolated_synth = Synth.tail(Server.default, \md_rms_isolated_from_busses, [
                    \inBusA, busIndexForA,
                    \inBusB, busIndexForB,
                    \fps, updateRateHz
                ]);
            });
            ("[RunAll/RMS] (tail) started on A=" ++ busIndexForA ++ "  B=" ++ busIndexForB).postln;
            nil
        });
    };

    // Listener to receive dB payload and update UI model
    oscKeyName = \md_rms_isolated_listener;
    installRmsListener = {
        var existing;
        existing = OSCdef.all.at(oscKeyName);
        if(existing.notNil) { existing.free };

        OSCdef(oscKeyName, { arg msg;
            if(msg.size >= 7) {
                currentDbAL = msg[3].asFloat;
                currentDbAR = msg[4].asFloat;
                currentDbBL = msg[5].asFloat;
                currentDbBR = msg[6].asFloat;
            };
            nil
        }, '/md/rms_isolated_dB', recvPort: NetAddr.langPort);

        "[RunAll/RMS] listener installed (/md/rms_isolated_dB)".postln;
    };

    // AppClock ticker: dB → 0..1 mapping and UI updates
    updateRoutine = Routine({
        var waitSeconds, mapDbToUi, floorDbLive, topDbLive;
        waitSeconds = 1.0 / updateRateHz;
        mapDbToUi = { arg dbValue, floorDb, topDb; ((dbValue - floorDb) / (topDb - floorDb)).clip(0.0, 1.0) };

        while({ rmsWindow.notNil and: { rmsWindow.isClosed.not } }) {
            floorDbLive = ~rms_isolated_floor_db ? defaultFloorDb;
            topDbLive   = ~rms_isolated_top_db   ? defaultTopDb;

            meterAL.value = mapDbToUi.(currentDbAL, floorDbLive, topDbLive);
            meterAR.value = mapDbToUi.(currentDbAR, floorDbLive, topDbLive);
            meterBL.value = mapDbToUi.(currentDbBL, floorDbLive, topDbLive);
            meterBR.value = mapDbToUi.(currentDbBR, floorDbLive, topDbLive);

            labelDbA.string = ("A: L=" ++ currentDbAL.round(0.1) ++ " dB  R=" ++ currentDbAR.round(0.1) ++ " dB");
            labelDbB.string = ("B: L=" ++ currentDbBL.round(0.1) ++ " dB  R=" ++ currentDbBR.round(0.1) ++ " dB");

            waitSeconds.yield;
        };
    }).play(AppClock);

    // Discover Ndef(\chainA/\chainB) busses and start synth
    getProxyBusInfo = { arg chainSymbol;
        var proxy, busObject, info;
        proxy = Ndef(chainSymbol);
        busObject = proxy.bus;
        info = (
            symbol: chainSymbol,
            playing: proxy.isPlaying,
            numChannels: proxy.numChannels,
            busIndex: busObject.notNil.if({ busObject.index }, { nil })
        );
        info
    };

    discoverBussesAndStart = {
        triesLeft = 20;
        Routine({
            var resolved;
            resolved = false;
            while({ triesLeft > 0 and: { resolved.not } }) {
                chainAInfo = getProxyBusInfo.(\chainA);
                chainBInfo = getProxyBusInfo.(\chainB);
                busIndexA  = chainAInfo[\busIndex];
                busIndexB  = chainBInfo[\busIndex];

                if(busIndexA.notNil and: { busIndexB.notNil }) {
                    ("[RunAll/RMS] chainA bus=" ++ busIndexA ++ " ch=" ++ chainAInfo[\numChannels]
                        ++ "  |  chainB bus=" ++ busIndexB ++ " ch=" ++ chainBInfo[\numChannels]).postln;
                    installRmsListener.();
                    installSynthDef.();
                    stopRmsSynth.();
                    startRmsSynthAtTail.(busIndexA, busIndexB);
                    resolved = true;
                }{
                    if(triesLeft == 20) { "[RunAll/RMS] waiting for chainA/chainB busses...".postln };
                    0.25.wait; triesLeft = triesLeft - 1;
                };
            };

            if(resolved.not) {
                "⚠️ [RunAll/RMS] could not resolve busses (chains not playing?). Start a source and re-run this file.".warn;
            };
        }).play(AppClock);
    };

    // Cleanup when window closes
    rmsWindow.onClose_({
        if(OSCdef(oscKeyName).notNil) { OSCdef(oscKeyName).free };
        if(~rms_isolated_synth.notNil) { ~rms_isolated_synth.free; ~rms_isolated_synth = nil };
        if(updateRoutine.notNil) { updateRoutine.stop; updateRoutine = nil };
        "[RunAll/RMS] closed and cleaned up.".postln;
    });

    // Kick off discovery and return window
    discoverBussesAndStart.();
    rmsWindow
};

// Master sequence: execute your four scripts in order, then start the RMS window
scheduleSequence = {
    AppClock.sched(0.00, {
        ensureBaseDir.();
        executeFileOnce.(fReset, "00_Reset_KnownClean_State.scd");
        nil
    });

    AppClock.sched(longPause, {
        executeFileOnce.(fStartHere, "01b_StartHere_NoReboot.scd");
        nil
    });

    AppClock.sched(longPause + mediumPause, {
        executeFileOnce.(fAssertStereo, "02S_AssertStereo_ChainAB_and_Retap_SAFE.scd");
        nil
    });

    AppClock.sched(longPause + mediumPause + smallPause, {
        executeFileOnce.(fTestSource, "02D_TestSource_CenteredStereo_Pulsed.scd");
        nil
    });

    // Start the isolated RMS HUD after bring-up + source have had a moment to run
    AppClock.sched(longPause + mediumPause + smallPause + longPause, {
        finalWindow = buildRmsIsolatedHud.();
        // Report and return
        "[RunAll] ✅ RMS_IsolatedHUD started.".postln;
        finalWindow;
    });
};

// Kick off the sequence and return the window when ready
scheduleSequence.();

// Return something immediately; the RMS window will be returned by the scheduled step.
// To see '-> a Window' in the post window after completion, re-select and run only the last line:
// finalWindow;
)
