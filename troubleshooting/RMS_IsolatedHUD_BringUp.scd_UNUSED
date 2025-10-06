// RMS_IsolatedHUD_BringUp.scd
//_v0.1.2
// MD 2025-09-29 19:10 BST

/* Purpose
   Show RMS (dB) at the *ends* of chainA and chainB in a NEW isolated window.
   - Reads Ndef(\chainA/\chainB) output busses directly: In.ar(bus, 2)
   - RMS per channel via RMS.ar(sig, 500)   // your spec
   - Convert to dBFS and map dB→0..1 for bar height (adjustable floor/top)
   - No shared OSC paths; no writes into existing HUD => zero interference

Style
   - var-first; descriptive lowercase names; AppClock for GUI; Server.default.bind for server ops;
     no server.sync; no non-local returns. Returns '-> a Window'.
*/

(
var // calibration (live‑tweakable via ~rms_isolated_floor_db / ~rms_isolated_top_db)
    defaultFloorDb, defaultTopDb, updateRateHz,

    // ui
    rmsWindow, labelTitle, labelDbA, labelDbB,
    meterAL, meterAR, meterBL, meterBR, updateRoutine,

    // latest measured dB (model for UI)
    currentDbAL, currentDbAR, currentDbBL, currentDbBR,

    // synth plumbing
    installSynthDef, startRmsSynthAtTail, stopRmsSynth,
    oscKeyName, installRmsListener,

    // bus discovery
    discoverBussesAndStart, getProxyBusInfo,
    chainAInfo, chainBInfo, busIndexA, busIndexB, triesLeft;

// ---- defaults (you can change live via the ~globals below) ----
defaultFloorDb = -72.0;    // visual floor
defaultTopDb   =   0.0;    // 0 dBFS → 1.0 (try +3.0 for extra headroom)
updateRateHz   =  15;

// allow live calibration overrides
~rms_isolated_floor_db = ~rms_isolated_floor_db ? defaultFloorDb;
~rms_isolated_top_db   = ~rms_isolated_top_db   ? defaultTopDb;

// ---- UI: simple absolute layout (no VLayout/HLayout pitfalls) ----
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

// initialize model values
currentDbAL = -140.0; currentDbAR = -140.0;
currentDbBL = -140.0; currentDbBR = -140.0;

// ---- SynthDef: read chain busses, compute RMS dB, SendReply (private path) ----
installSynthDef = {
    Server.default.bind({
        SynthDef(\md_rms_isolated_from_busses, {
            arg inBusA = 0, inBusB = 0, fps = 15;
            var sigA, sigB, aL, aR, bL, bR;
            var rmsAL, rmsAR, rmsBL, rmsBR;
            var dbAL, dbAR, dbBL, dbBR;
            var tick, minLinear;

            sigA = In.ar(inBusA, 2);
            sigB = In.ar(inBusB, 2);

            aL = sigA[0];
            aR = (sigA.size > 1).if({ sigA[1] }, { sigA[0] });
            bL = sigB[0];
            bR = (sigB.size > 1).if({ sigB[1] }, { sigB[0] });

            // RMS per channel with 500 Hz smoothing (your spec)
            rmsAL = RMS.ar(aL, 500);
            rmsAR = RMS.ar(aR, 500);
            rmsBL = RMS.ar(bL, 500);
            rmsBR = RMS.ar(bR, 500);

            // dBFS with guard floor
            minLinear = 1e-9;
            dbAL = (max(rmsAL, minLinear)).log10 * 20.0;
            dbAR = (max(rmsAR, minLinear)).log10 * 20.0;
            dbBL = (max(rmsBL, minLinear)).log10 * 20.0;
            dbBR = (max(rmsBR, minLinear)).log10 * 20.0;

            tick = Impulse.kr(fps);
            // Private OSC: 4 dB values [A_L, A_R, B_L, B_R]
            SendReply.kr(tick, "/md/rms_isolated_dB", [dbAL, dbAR, dbBL, dbBR]);
        }).add;
    });
    "[RMS HUD] SynthDef \\md_rms_isolated_from_busses installed.".postln;
};

// Start the reader **at tail** so it runs AFTER the chains write to their busses
stopRmsSynth = {
    if(~rms_isolated_synth.notNil) {
        ~rms_isolated_synth.free; ~rms_isolated_synth = nil;
        "[RMS HUD] previous synth stopped.".postln;
    };
};

startRmsSynthAtTail = { arg busA, busB;
    AppClock.sched(0.20, {   // small delay after .add; no server.sync per your rules
        Server.default.bind({
            ~rms_isolated_synth = Synth.tail(Server.default, \md_rms_isolated_from_busses, [
                \inBusA, busA, \inBusB, busB, \fps, updateRateHz
            ]);
        });
        ("[RMS HUD] (tail) started on A=" ++ busA ++ "  B=" ++ busB).postln;
        nil
    });
};

// ---- Listener: receive private dB and update the UI model ----
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

    "[RMS HUD] listener installed (/md/rms_isolated_dB)".postln;
};

// ---- AppClock ticker: map dB -> 0..1 and set meters + labels ----
updateRoutine = Routine({
    var waitSeconds, floorDbLive, topDbLive, mapDbToUi;
    waitSeconds = 1.0 / updateRateHz;

    mapDbToUi = { arg dbValue, floorDb, topDb;
        ((dbValue - floorDb) / (topDb - floorDb)).clip(0.0, 1.0)
    };

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

// ---- bus discovery: wait briefly until chainA/B expose busses, then start ----
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
                ("[RMS HUD] chainA bus=" ++ busIndexA ++ " ch=" ++ chainAInfo[\numChannels]
                    ++ "  |  chainB bus=" ++ busIndexB ++ " ch=" ++ chainBInfo[\numChannels]).postln;
                installSynthDef.();
                stopRmsSynth.();
                startRmsSynthAtTail.(busIndexA, busIndexB);  // **TAIL START**
                resolved = true;
            }{
                if(triesLeft == 20) { "[RMS HUD] waiting for chainA/chainB busses...".postln };
                0.25.wait; triesLeft = triesLeft - 1;
            };
        };

        if(resolved.not) {
            "⚠️ [RMS HUD] could not resolve busses (chains not playing?). Start a source and re-evaluate this block.".warn;
        };
    }).play(AppClock);
};

// ---- wire up listener and start discovery ----
installRmsListener.();
discoverBussesAndStart.();

// ---- cleanup on close ----
rmsWindow.onClose_({
    if(OSCdef(oscKeyName).notNil) { OSCdef(oscKeyName).free };
    if(~rms_isolated_synth.notNil) { ~rms_isolated_synth.free; ~rms_isolated_synth = nil };
    if(updateRoutine.notNil) { updateRoutine.stop; updateRoutine = nil };
    "[RMS HUD] closed and cleaned up.".postln;
});

// return window
rmsWindow;
)
