// RMS_From_ChainAB_Busses_ToHUD.scd
// v0.1.0
// MD 2025-09-29

/* Purpose
   - Read audio at the *ends* of chainA and chainB via their Ndef output busses.
   - Compute RMS per channel using RMS.ar(sig, 500).
   - Convert to dBFS, map to 0..1 for display headroom, and send to /md/levels
     (the standard PerfHUD path: [A_L, A_R, B_L, B_R]).
   - Also send raw dBFS to /md/rms_db so we can verify numbers in the console.

Style
   - var-first; descriptive lowercase; Server.default.bind for server ops; AppClock for UI; no server.sync.
*/

(
var getProxyBusInfo, chainAProxy, chainBProxy, busAIndex, busBIndex, channelsA, channelsB;
var uiFloorDb, uiTopDb, updatesPerSecond;
var installSynthDef, startRmsMeter, installDbPrinter, stopExisting, sanityReport;

// --- configuration (adjust only these if needed) ---
uiFloorDb        = -72.0;  // visual floor
uiTopDb          =   3.0;  // 0 dBFS maps to 1.0 (use +3.0 for extra headroom)
updatesPerSecond = 15;     // HUD refresh cadence

// Helpers
getProxyBusInfo = { arg symbol;
    var proxy, busObject, infoDict;
    proxy = Ndef(symbol);
    busObject = proxy.bus;
    infoDict = (
        symbol: symbol,
        playing: proxy.isPlaying,
        numChannels: proxy.numChannels,
        busIndex: busObject.notNil.if({ busObject.index }, { nil })
    );
    infoDict
};

// 0) Inspect chain busses (so we *know* what we’re reading)
chainAProxy = getProxyBusInfo.(\chainA);
chainBProxy = getProxyBusInfo.(\chainB);
busAIndex   = chainAProxy[\busIndex];
busBIndex   = chainBProxy[\busIndex];
channelsA   = chainAProxy[\numChannels];
channelsB   = chainBProxy[\numChannels];

sanityReport = "[RMS] chainA bus=" ++ (busAIndex ? "nil")
    ++ "  chans=" ++ channelsA
    ++ "   |   chainB bus=" ++ (busBIndex ? "nil")
    ++ "  chans=" ++ channelsB;
sanityReport.postln;

if(busAIndex.isNil or: { busBIndex.isNil }) {
    "⚠️ Could not get Ndef bus indices (are chainA/chainB playing?). Aborting RMS bring-up.".warn;
    ^nil;
};

// 1) Define one synth to read both busses, compute RMS→dB→UI and send to HUD
installSynthDef = {
    Server.default.bind({
        SynthDef(\md_rms_from_busses, {
            arg inBusA = 0, inBusB = 0, fps = 15, floorDb = -72, topDb = 0;

            var sigA, sigB, aL, aR, bL, bR;
            var rmsAL, rmsAR, rmsBL, rmsBR;
            var dbAL, dbAR, dbBL, dbBR;
            var uiAL, uiAR, uiBL, uiBR;
            var tick, minLin;

            // Read 2 channels from each bus; duplicate left if mono
            sigA = In.ar(inBusA, 2);
            sigB = In.ar(inBusB, 2);

            aL = sigA[0];
            aR = (sigA.size > 1).if({ sigA[1] }, { sigA[0] });

            bL = sigB[0];
            bR = (sigB.size > 1).if({ sigB[1] }, { sigB[0] });

            // RMS at audio rate (user-specified: RMS.ar(sig, 500) ~ 500 Hz lowpass)
            rmsAL = RMS.ar(aL, 500);
            rmsAR = RMS.ar(aR, 500);
            rmsBL = RMS.ar(bL, 500);
            rmsBR = RMS.ar(bR, 500);

            // Convert to dBFS (guard floor)
            minLin = 1e-9;
            dbAL = (max(rmsAL, minLin)).log10 * 20.0;
            dbAR = (max(rmsAR, minLin)).log10 * 20.0;
            dbBL = (max(rmsBL, minLin)).log10 * 20.0;
            dbBR = (max(rmsBR, minLin)).log10 * 20.0;

            // Map dBFS -> 0..1 for HUD (headroom)
            uiAL = ((dbAL - floorDb) / (topDb - floorDb)).clip(0.0, 1.0);
            uiAR = ((dbAR - floorDb) / (topDb - floorDb)).clip(0.0, 1.0);
            uiBL = ((dbBL - floorDb) / (topDb - floorDb)).clip(0.0, 1.0);
            uiBR = ((dbBR - floorDb) / (topDb - floorDb)).clip(0.0, 1.0);

            // Emit both: raw dB (for console) and mapped UI (for HUD)
            tick = Impulse.kr(fps);

            // For verification
            SendReply.kr(tick, "/md/rms_db", [dbAL, dbAR, dbBL, dbBR]);

            // For HUD: /md/levels expects [A_L, A_R, B_L, B_R]
            SendReply.kr(tick, "/md/levels", [uiAL, uiAR, uiBL, uiBR]);
        }).add;
    });
    "[RMS] SynthDef \\md_rms_from_busses installed.".postln;
};

// 2) Stop any previous RMS meter synth; start a fresh one on the detected busses
stopExisting = {
    if(~md_rmsSynth.notNil) {
        ~md_rmsSynth.free; ~md_rmsSynth = nil;
        "[RMS] previous md_rms_from_busses stopped.".postln;
    };
};

startRmsMeter = {
    Server.default.bind({
        ~md_rmsSynth = Synth(\md_rms_from_busses, [
            \inBusA, busAIndex,
            \inBusB, busBIndex,
            \fps, updatesPerSecond,
            \floorDb, uiFloorDb,
            \topDb, uiTopDb
        ]);
    });
    ("[RMS] started on A=" ++ busAIndex ++ "  B=" ++ busBIndex
        ++ "  floor=" ++ uiFloorDb ++ " dB  top=" ++ uiTopDb ++ " dB").postln;
};

// 3) Print a few dB lines to console so we *see* the measured numbers
installDbPrinter = {
    var keyName, linesRemaining;
    keyName = \md_rms_db_console;
    linesRemaining = 8;

    if(OSCdef(keyName).notNil) { OSCdef(keyName).free };
    OSCdef(keyName, { arg message;
        var dbAL, dbAR, dbBL, dbBR, line;
        if(message.size >= 5) {
            dbAL = message[3].round(0.1);
            dbAR = message[4].round(0.1);
            dbBL = message[5].round(0.1);
            dbBR = message[6].round(0.1);
            line = "[RMS dB]  A: L=" ++ dbAL ++ "  R=" ++ dbAR
                ++ "   |   B: L=" ++ dbBL ++ "  R=" ++ dbBR;
            line.postln;
            linesRemaining = linesRemaining - 1;
            if(linesRemaining <= 0) {
                OSCdef(keyName).free;
                "[RMS dB] console printer finished.".postln;
            };
        };
    }, '/md/rms_db');
};

// Execute
installSynthDef.();
stopExisting.();
startRmsMeter.();
installDbPrinter.();
)
