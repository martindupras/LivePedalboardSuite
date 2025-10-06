// 00_Reset_KnownClean_State.scd
// v1.0.1
// MD 20250929-0918

(
// Purpose
// - Close MagicDisplay windows; free HUD OSCdefs/bridges/probes.
// - Stop Ndefs; clear server tree; clear HUD dictionaries.
// Style
// - var-first; no server.sync; server ops in Server.default.bind; UI via AppClock.

var closeMagicDisplayWindows, freeHudReceivers, stopNdefs, clearGlobals;

closeMagicDisplayWindows = {
    var wins, i, w, nm;
    wins = Window.allWindows; i = 0;
    while { i < wins.size } {
        w = wins[i];
        nm = w.tryPerform(\name);
        if(nm.notNil and: { nm.asString.beginsWith("MagicDisplayGUI") }) { w.close };
        i = i + 1;
    };
};

freeHudReceivers = {
    [ \md_levels_hud, \md_levels_gui_bridge, \probe_levels, \probe_levels_gui, \probe_levels_bus ].do { |k|
        var d = OSCdef.all.at(k);
        if(d.notNil) { d.free };
    };
};

stopNdefs = {
    Server.default.bind({
        [ \chainA, \chainB, \testmelody, \ts0 ].do { |k|
            if(Ndef(k).isPlaying) { Ndef(k).stop };
        };
        s.defaultGroup.freeAll;
    });
};

clearGlobals = {
    ~md_levelsById   = IdentityDictionary.new;
    ~md_lastMsgStamp = SystemClock.seconds.asFloat;
    ~md_busTapA = nil; ~md_busTapB = nil;
    ~system = nil; ~mpb = nil; ~gui = nil;
};

closeMagicDisplayWindows.value;
freeHudReceivers.value;
stopNdefs.value;
clearGlobals.value;

"✅ Reset: GUI closed, OSCdefs freed, Ndefs stopped, globals cleared.".postln;
)
// 01b_StartHere_NoReboot.scd
// v0.6.3
// MD 20250929-12:25

(
// Purpose
// - Bring up LivePedalboardSuite when the server is already running (beep booted it).
// - Avoids reboot races; opens the single GUI window; enables GUI taps.
// Style
// - var-first; no server.sync; Server.default.bind; AppClock for UI.

var systemRef, windowRef;
var ensureAudioProxies, startSystem, findMagicDisplayWindow, frontWindow, afterBringUp;
var ensureGui; // NEW

ensureAudioProxies = {
    Server.default.bind({
        if(Ndef(\chainA).source.isNil) { Ndef(\chainA, { \in.ar(2) }) };
        if(Ndef(\chainB).source.isNil) { Ndef(\chainB, { \in.ar(2) }) };
        if(Ndef(\ts0   ).source.isNil) { Ndef(\ts0,    { Silent.ar(2) }) };
        if(Ndef(\testmelody).source.isNil) {
            Ndef(\testmelody, {
                // initial testmelody (will be replaced by a centered one in 02D)
                var trig = Impulse.kr(2.4);
                var sel  = Demand.kr(trig, 0, Dwhite(0, 4, inf));
                var scale = [60, 62, 64, 67, 69];
                var f = Select.kr(sel, scale).midicps;
                var env = Decay2.kr(trig, 0.01, 0.35);
                var pan = 0.0; // neutral here; will be overridden anyway
                Pan2.ar(SinOsc.ar(f) * env * 0.22, pan)
            });
        };
        Ndef(\chainA).ar(2); Ndef(\chainB).ar(2);
        Ndef(\ts0).ar(2);    Ndef(\testmelody).ar(2);
    });
};

startSystem = {
    if(s.serverRunning.not) { "⚠️ Server not running; run 03_Sanity_Beep first.".postln };
    systemRef = LivePedalboardSystem.new(nil);
    systemRef.bringUpAll; // PerfHUD if present; else GridDemo
    ~system = systemRef;
    ~mpb    = systemRef.pedalboard;
    ~gui    = systemRef.statusDisplay; // may be nil when PerfHUD is used
};

findMagicDisplayWindow = {
    Window.allWindows.detect({ |w|
        var nm = w.tryPerform(\name);
        nm.notNil and: { nm.asString.beginsWith("MagicDisplayGUI") }
    })
};

frontWindow = { |w|
    if(w.notNil) {
        AppClock.sched(0.0, { w.front; nil });
    };
    w
};

afterBringUp = { |lps|
    if(lps.respondsTo(\installAdapterBridge)) { lps.installAdapterBridge };
    if(lps.respondsTo(\enableAutoMeters))     { lps.enableAutoMeters(24, 0.35) };
    frontWindow.(findMagicDisplayWindow.());
};

// NEW — ensure we always have a usable ~gui handle for later HUD steps.
// - If statusDisplay was set (GridDemo path), keep it.
// - If nil (PerfHUD path), detect the window shortly after creation.
// - If still nil, fallback to a new GridDemo and bind it to the pedalboard.
ensureGui = {
    var giveUpAt;
    // 1) quick capture if bringUpAll already assigned a controller
    if(~gui.notNil) { ^~gui };

    // 2) short polling window to catch PerfHUD’s window (built on AppClock)
    giveUpAt = SystemClock.seconds + 0.80;
    AppClock.sched(0.00, {
        if(~gui.isNil) {
            ~gui = findMagicDisplayWindow.(); // this will be a Window (PerfHUD)
        };
        if(~gui.isNil and: { SystemClock.seconds < giveUpAt }) { 0.05 } {
            // 3) fallback to GridDemo controller (exposes highlightCurrentColumn/setOperations)
            if(~gui.isNil) {
                // Close any stray MagicDisplay windows to keep a single instance policy
                Window.allWindows
                .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
                .do(_.close);

                ~gui = MagicDisplayGUI_GridDemo.new;  // controller object
                if(~mpb.notNil and: { ~mpb.respondsTo(\setDisplay) }) {
                    ~mpb.setDisplay(~gui);
                };
                ~gui.window.front.alwaysOnTop_(true);
            };
            nil
        }
    });
};

// ——— bring-up sequence ———

ensureAudioProxies.value;
startSystem.value;

// Bring the window to front and arm meters
windowRef = afterBringUp.(systemRef);

// Ensure ~gui is bound for later HUD test steps (02B / 02F)
ensureGui.value;

// Return a window for your “-> a Window” acceptance pattern
windowRef
)
// 02S_AssertStereo_ChainAB_and_Retap_SAFE.scd
// v0.1.1
// MD 20250929-1120

/* Purpose
   - Assert stereo + playing for Ndef(\chainA) and Ndef(\chainB) WITHOUT muting/rewiring.
   - (Re)install safe visual taps that send /md/levels (replyIDs A=2001, B=2002).
   - Use unique filter keys and ALWAYS return 'in' (pure pass-through).
   - No server.sync; Server.default.bind for server ops; var-first; lowercase.

   Notes
   - This script does NOT touch sources, OSCdefs, or HUD listeners.
   - If an older tap with the same key exists, .filter replaces it safely.
*/

(
var rateHz, atk, rel, floorAmp, path;
var busA, busB, playA, playB, chA, chB, warn;

rateHz   = 24;
atk      = 0.01;
rel      = 0.20;
floorAmp = 1e-5;
path     = "/md/levels";

warn = { |txt| ("[02S_SAFE] " ++ txt).warn };

// --- assert stereo/playing & re-tap (no frees, no stops)
Server.default.bind({
    // ensure AR 2-ch busses are alive
    Ndef(\chainA).ar(2);
    Ndef(\chainB).ar(2);

    // quick diagnostics (posts only; never mutates play state)
    busA = Ndef(\chainA).bus;
    busB = Ndef(\chainB).bus;
    playA = Ndef(\chainA).isPlaying;
    playB = Ndef(\chainB).isPlaying;
    chA = busA.notNil.if({ busA.numChannels }, { -1 });
    chB = busB.notNil.if({ busB.numChannels }, { -1 });

    ("[02S_SAFE] A: playing=" ++ playA ++ " ch=" ++ chA).postln;
    ("[02S_SAFE] B: playing=" ++ playB ++ " ch=" ++ chB).postln;

    if(chA != 2) { warn.("chainA bus is not stereo (" ++ chA ++ "); enforcing ar(2)"); Ndef(\chainA).ar(2); };
    if(chB != 2) { warn.("chainB bus is not stereo (" ++ chB ++ "); enforcing ar(2)"); Ndef(\chainB).ar(2); };

    // --- SAFE visual taps (A=2001, B=2002); return 'in'
    Ndef(\chainA).filter(\mdVisTapA, { |in|
        var sig, aL, aR;
        sig = in.isArray.if({ in }, { [in, in] });
        aL = Amplitude.kr(sig[0], atk, rel).clip(floorAmp, 1.0);
        aR = Amplitude.kr(sig[1], atk, rel).clip(floorAmp, 1.0);
        SendReply.kr(Impulse.kr(rateHz), path, [aL, aR], 2001);
        in
    });

    Ndef(\chainB).filter(\mdVisTapB, { |in|
        var sig, aL, aR;
        sig = in.isArray.if({ in }, { [in, in] });
        aL = Amplitude.kr(sig[0], atk, rel).clip(floorAmp, 1.0);
        aR = Amplitude.kr(sig[1], atk, rel).clip(floorAmp, 1.0);
        SendReply.kr(Impulse.kr(rateHz), path, [aL, aR], 2002);
        in
    });
});
"[*] 02S_SAFE: stereo asserted; taps (A=2001,B=2002) sending to /md/levels".postln;
)
// 02D_TestSource_CenteredStereo_Pulsed.scd
// v0.1.1
// MD 20250929-0948

(
// Purpose
// - Centered stereo pulses (equal L/R), easy to see on meters without drone.
// Style
// - var-first; server ops in Server.default.bind.

var install;

install = {
    Server.default.bind({
        Ndef(\testmelody, {
            var trig = Impulse.kr(2);                // 2 pulses per second
            var env  = Decay2.kr(trig, 0.01, 0.22);  // short visual envelope
            var sig  = SinOsc.ar(440) * env * 0.30;  // moderate level
            [sig, sig]                               // equal L/R
        });
        Ndef(\testmelody).ar(2);
    });
    "🎛️ testmelody set to centered stereo pulses (equal L/R).".postln;
};

install.value;
)
// RMS_IsolatedHUD.scd
// v0.1.0
// MD 2025-09-29 19:25 BST

/* WORKING
Run:
troubleshooting/00_Reset_KnownClean_State.scd
troubleshooting/01b_StartHere_NoReboot.scd
(Optional) troubleshooting/02S_AssertStereo_ChainAB_and_Retap_SAFE.scd
Start a source (e.g. troubleshooting/02D_TestSource_CenteredStereo_Pulsed.scd)
Run troubleshooting/RMS_IsolatedHUD.scd → -> a Window, bars move with RMS (dB).

*/


/* Purpose
   Display RMS (dBFS) measured at the *ends* of chainA and chainB in a new, isolated GUI window.
   - Reads Ndef(\chainA/\chainB) output busses directly with In.ar(bus, 2).
   - RMS per channel using RMS.ar(sig, 500) (your specification).
   - Converts to dBFS and maps dB→0..1 for bar height (adjustable floor/top).
   - Uses a private OSC path for UI updates; does not touch PerfHUD/GridDemo responders.

Style
   - var-first; descriptive lowercase names; AppClock for GUI; Server.default.bind for server ops.
   - No server.sync; no non-local returns. On success, returns '-> a Window'.
*/

(
var // calibration (you can tweak live after launch via ~rms_isolated_floor_db / ~rms_isolated_top_db)
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
defaultFloorDb = -72.0;    // visual floor (dBFS)
defaultTopDb   =   0.0;    // 0 dBFS → 1.0 (try +3.0 for extra visual headroom at full scale)
updateRateHz   =  15;      // UI update cadence (Hz)

// allow live calibration overrides
~rms_isolated_floor_db = ~rms_isolated_floor_db ? defaultFloorDb;
~rms_isolated_top_db   = ~rms_isolated_top_db   ? defaultTopDb;

// ---- UI: simple absolute layout (no layout shorthands to avoid asView errors) ----
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

            // RMS per channel with 500 Hz smoothing (as requested)
            rmsAL = RMS.ar(aLeft,  500);
            rmsAR = RMS.ar(aRight, 500);
            rmsBL = RMS.ar(bLeft,  500);
            rmsBR = RMS.ar(bRight, 500);

            // dBFS with guard floor
            minLinear = 1e-9;
            dbAL = (max(rmsAL, minLinear)).log10 * 20.0;
            dbAR = (max(rmsAR, minLinear)).log10 * 20.0;
            dbBL = (max(rmsBL, minLinear)).log10 * 20.0;
            dbBR = (max(rmsBR, minLinear)).log10 * 20.0;

            tick = Impulse.kr(fps);

            // Private OSC payload: [A_L_dB, A_R_dB, B_L_dB, B_R_dB]
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

startRmsSynthAtTail = { arg busIndexForA, busIndexForB;
    AppClock.sched(0.20, {   // small delay after .add; no server.sync per your rules
        Server.default.bind({
            ~rms_isolated_synth = Synth.tail(Server.default, \md_rms_isolated_from_busses, [
                \inBusA, busIndexForA,
                \inBusB, busIndexForB,
                \fps, updateRateHz
            ]);
        });
        ("[RMS HUD] (tail) started on A=" ++ busIndexForA ++ "  B=" ++ busIndexForB).postln;
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

// ---- bus discovery: wait until chainA/B expose busses, then start ----
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
                startRmsSynthAtTail.(busIndexA, busIndexB);  // **TAIL START** ensures correct node order
                resolved = true;
            }{
                if(triesLeft == 20) { "[RMS HUD] waiting for chainA/chainB busses...".postln };
                0.25.wait; triesLeft = triesLeft - 1;
            };
        };

        if(resolved.not) {
            "⚠️ [RMS HUD] could not resolve busses (chains not playing?). Start a source and re-evaluate this file.".warn;
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

// return window so you see '-> a Window'
rmsWindow;
)
