// NEARLY WORKING just meters not moving.

// turnintooneplease_singleblock_race_hardened.scd
// One-shot bring-up with explicit CURRENT routing (A), safe taps, and RMS HUD.
// Strategy: avoid freeAll; clear/rebuild Ndefs; schedule steps to avoid group races.
(
var // ── helpers ──
post, warn, now,

// ── reset/bring-up vars ──
systemRef, windowRef, ensureAudioProxies, startSystem, findMagicDisplayWindow, frontWindow, afterBringUp, ensureGui,
resetLight, installSafeTapsLater, connectAndPlayLater, installCenteredPulse, reportPlayState,

// ── RMS HUD vars ──
rmsWindow, labelDbA, labelDbB, meterAL, meterAR, meterBL, meterBR, updateRoutine,
currentDbAL, currentDbAR, currentDbBL, currentDbBR,
defaultFloorDb, defaultTopDb, updateRateHz,
installSynthDef, stopRmsSynth, startRmsSynthAtTail, oscKeyName, installRmsListener,
getProxyBusInfo, discoverBussesAndStart;

post = { |txt| txt.postln };
warn = { |txt| ("⚠️ " ++ txt).warn };
now  = { SystemClock.seconds.round(0.001) };

// ───────────────────────────── 0) LIGHT RESET (no freeAll) ─────────────────────────────
resetLight = {
    // Close our GUI windows but do NOT free server groups globally.
    Window.allWindows.do { |w|
        var nm = w.tryPerform(\name);
        if(nm.notNil and: { nm.asString.beginsWith("MagicDisplayGUI") or: { nm.asString.contains("RMS HUD") }}) { w.close };
    };
    // Free only our known OSCdefs (do not touch others)
    [ \md_levels_hud, \md_levels_gui_bridge, \probe_levels, \probe_levels_gui, \probe_levels_bus,
      \md_rms_isolated_listener ].do { |k| var d = OSCdef.all.at(k); if(d.notNil) { d.free } };

    // Stop and clear only the Ndefs we control; this rebuilds their proxy groups safely.
    Server.default.bind({
        [ \chainA, \chainB, \testmelody, \ts0 ].do { |k|
            if(Ndef(k).isPlaying) { Ndef(k).stop };
        };
    });
    Ndef(\chainA).clear; Ndef(\chainB).clear;  // remove filters & old nodes (no race with global groups)
    post.("✅ [" ++ now.() ++ "] Light reset done (no freeAll).");
};

// ──────────────────────────── 1) SYSTEM BRING-UP (GUI + meters) ────────────────────────────
ensureAudioProxies = {
    Server.default.bind({
        if(Ndef(\chainA).source.isNil) { Ndef(\chainA, { \in.ar(2) }) };
        if(Ndef(\chainB).source.isNil) { Ndef(\chainB, { \in.ar(2) }) };
        if(Ndef(\ts0 ).source.isNil)   { Ndef(\ts0,  { Silent.ar(2) }) };
        if(Ndef(\testmelody).source.isNil) {
            Ndef(\testmelody, { Silent.ar(2) }); // temporary; we install centered pulse later
        };
        // Ensure 2ch
        Ndef(\chainA).ar(2); Ndef(\chainB).ar(2); Ndef(\ts0).ar(2); Ndef(\testmelody).ar(2);
    });
    post.("🔧 [" ++ now.() ++ "] Proxies ensured (chainA/B/ts0/testmelody ar(2)).");
};

startSystem = {
    if(s.serverRunning.not) { "Booting server…".postln; s.waitForBoot }; // allowed; you forbid server.sync, not waitForBoot
    systemRef = LivePedalboardSystem.new(nil);
    systemRef.bringUpAll;  // may create PerfHUD or GridDemo
    ~system = systemRef; ~mpb = systemRef.pedalboard; ~gui = systemRef.statusDisplay;
    post.("🚀 [" ++ now.() ++ "] bringUpAll dispatched.");
};

findMagicDisplayWindow = {
    Window.allWindows.detect({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
};

frontWindow = { |w| if(w.notNil) { AppClock.sched(0.0, { w.front; nil }) }; w };

afterBringUp = { |lps|
    if(lps.respondsTo(\installAdapterBridge)) { lps.installAdapterBridge };
    if(lps.respondsTo(\enableAutoMeters))     { lps.enableAutoMeters(24, 0.35) };
    frontWindow.(findMagicDisplayWindow.());
};

ensureGui = {
    var giveUpAt;
    if(~gui.notNil) { ^~gui };
    giveUpAt = SystemClock.seconds + 0.80;
    AppClock.sched(0.00, {
        if(~gui.isNil) { ~gui = findMagicDisplayWindow.() };
        if(~gui.isNil and: { SystemClock.seconds < giveUpAt }) { 0.05 } {
            if(~gui.isNil) {
                Window.allWindows
                .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
                .do(_.close);
                ~gui = MagicDisplayGUI_GridDemo.new;
                if(~mpb.notNil and: { ~mpb.respondsTo(\setDisplay) }) { ~mpb.setDisplay(~gui) };
                ~gui.window.front.alwaysOnTop_(true);
            };
            nil
        }
    });
};

// ──────────────────────────── 2) CONNECT + SAFE TAPS (with small delays) ────────────────────────────
reportPlayState = {
    ["[PLAY] A=", Ndef(\chainA).isPlaying, "B=", Ndef(\chainB).isPlaying].postln;
};

connectAndPlayLater = {
    // Delay a hair after bringUpAll so any internal server ops settle.
    AppClock.sched(0.15, {
        Server.default.bind({
            " [PATCH] testmelody → chainA; play A / stop B".postln;
            // Install the centered pulse source right before connecting
            Ndef(\testmelody, {
                var trig = Impulse.kr(2), env = Decay2.kr(trig, 0.01, 0.22);
                var sig = SinOsc.ar(440) * env * 0.30; [sig, sig] // equal L/R
            });
            Ndef(\testmelody).ar(2);

            // Freshly (re)play sinks to create fresh groups if needed
            Ndef(\chainA).play; Ndef(\chainB).stop;

            // JITLib connect: explicit source -> CURRENT (A)
            Ndef(\testmelody) <<> Ndef(\chainA);
        });
        reportPlayState.();
        nil
    });
};

installSafeTapsLater = {
    // Install pass-through taps AFTER we know chainA/B have groups again.
    AppClock.sched(0.25, {
        Server.default.bind({
            Ndef(\chainA).filter(\mdVisTapA, { |in|
                var sig = in.asArray;
                var aL = Amplitude.kr(sig[0], 0.01, 0.20).clip(1e-5, 1);
                var aR = Amplitude.kr(sig.wrapAt(1), 0.01, 0.20).clip(1e-5, 1);
                SendReply.kr(Impulse.kr(24), "/md/levels", [aL, aR], 2001); in
            });
            Ndef(\chainB).filter(\mdVisTapB, { |in|
                var sig = in.asArray;
                var aL = Amplitude.kr(sig[0], 0.01, 0.20).clip(1e-5, 1);
                var aR = Amplitude.kr(sig.wrapAt(1), 0.01, 0.20).clip(1e-5, 1);
                SendReply.kr(Impulse.kr(24), "/md/levels", [aL, aR], 2002); in
            });
        });
        "[*] SAFE taps (A=2001,B=2002) installed.".postln;
        nil
    });
};

// ──────────────────────────── 3) RMS HUD (robust bus discovery) ────────────────────────────
defaultFloorDb = -72.0; defaultTopDb = 0.0; updateRateHz = 15;
~rms_isolated_floor_db = ~rms_isolated_floor_db ? defaultFloorDb;
~rms_isolated_top_db   = ~rms_isolated_top_db   ? defaultTopDb;

rmsWindow = Window("RMS HUD", Rect(100,100,440,210)).front;
meterAL = LevelIndicator(rmsWindow, Rect( 40,40,60,110)).drawsPeak_(false);
meterAR = LevelIndicator(rmsWindow, Rect(120,40,60,110)).drawsPeak_(false);
meterBL = LevelIndicator(rmsWindow, Rect(230,40,60,110)).drawsPeak_(false);
meterBR = LevelIndicator(rmsWindow, Rect(310,40,60,110)).drawsPeak_(false);
labelDbA = StaticText(rmsWindow, Rect(10,175,210,18)).string_("A: L=-∞ R=-∞");
labelDbB = StaticText(rmsWindow, Rect(220,175,210,18)).string_("B: L=-∞ R=-∞");

currentDbAL = -140.0; currentDbAR = -140.0; currentDbBL = -140.0; currentDbBR = -140.0;

installSynthDef = {
    Server.default.bind({
        SynthDef(\md_rms_isolated_from_busses, {
            arg inBusA = 0, inBusB = 0, fps = 15;
            var sigA = In.ar(inBusA,2), sigB = In.ar(inBusB,2);
            var rmsAL = RMS.ar(sigA[0], 500), rmsAR = RMS.ar(sigA[1], 500);
            var rmsBL = RMS.ar(sigB[0], 500), rmsBR = RMS.ar(sigB[1], 500);
            var dbAL = (max(rmsAL,1e-9)).log10*20, dbAR = (max(rmsAR,1e-9)).log10*20;
            var dbBL = (max(rmsBL,1e-9)).log10*20, dbBR = (max(rmsBR,1e-9)).log10*20;
            SendReply.kr(Impulse.kr(fps), "/md/rms_isolated_dB", [dbAL, dbAR, dbBL, dbBR]);
        }).add;
    });
    "[RMS HUD] SynthDef added.".postln;
};

stopRmsSynth = {
    if(~rms_isolated_synth.notNil) { ~rms_isolated_synth.free; ~rms_isolated_synth = nil; "[RMS HUD] old synth freed.".postln; };
};

startRmsSynthAtTail = { |busIndexForA, busIndexForB|
    AppClock.sched(0.05, {  // small delay after .add; no server.sync
        Server.default.bind({
            ~rms_isolated_synth = Synth.tail(Server.default, \md_rms_isolated_from_busses, [
                \inBusA, busIndexForA, \inBusB, busIndexForB, \fps, updateRateHz
            ]);
        });
        ("[RMS HUD] started A=" ++ busIndexForA ++ " B=" ++ busIndexForB).postln;
        nil
    });
};

oscKeyName = \md_rms_isolated_listener;
installRmsListener = {
    var existing = OSCdef.all.at(oscKeyName); if(existing.notNil) { existing.free };
    OSCdef(oscKeyName, { |msg|
        if(msg.size >= 7) {
            currentDbAL = msg[3].asFloat; currentDbAR = msg[4].asFloat;
            currentDbBL = msg[5].asFloat; currentDbBR = msg[6].asFloat;
        }; nil
    }, '/md/rms_isolated_dB', recvPort: NetAddr.langPort);
    "[RMS HUD] listener installed.".postln;
};

getProxyBusInfo = { |sym|
    var px = Ndef(sym), busObj = px.bus;
    (
        symbol: sym,
        playing: px.isPlaying,
        numChannels: px.numChannels,
        busIndex: busObj.notNil.if({ busObj.index }, { nil })
    )
};

discoverBussesAndStart = {
    var triesLeft = 24; // ~6 s at 0.25s step
    Routine({
        var resolved = false;
        while({ triesLeft > 0 and: { resolved.not } }) {
            var a = getProxyBusInfo.(\chainA), b = getProxyBusInfo.(\chainB);
            if(a[\busIndex].notNil and: { b[\busIndex].notNil }) {
                installSynthDef.(); stopRmsSynth.();
                startRmsSynthAtTail.(a[\busIndex], b[\busIndex]);
                resolved = true;
            }{
                if(triesLeft == 24) { "[RMS HUD] waiting for chainA/chainB busses…".postln };
                0.25.wait; triesLeft = triesLeft - 1;
            };
        };
        if(resolved.not) { warn.("[RMS HUD] could not resolve busses; play state?") };
    }).play(AppClock);
};

// ──────────────────────────── 4) RUN SEQUENCE ────────────────────────────
resetLight.();
ensureAudioProxies.();
startSystem.();
windowRef = afterBringUp.(systemRef);
ensureGui.();

connectAndPlayLater.();   // schedules at t+0.15
installSafeTapsLater.();  // schedules at t+0.25

installRmsListener.();
discoverBussesAndStart.(); // will start synth once busses are known

// clean-up when closing HUD
rmsWindow.onClose_({
    if(OSCdef(oscKeyName).notNil) { OSCdef(oscKeyName).free };
    if(~rms_isolated_synth.notNil) { ~rms_isolated_synth.free; ~rms_isolated_synth = nil };
    if(updateRoutine.notNil) { updateRoutine.stop; updateRoutine = nil };
    "[RMS HUD] closed.".postln;
});

// return window so you see '-> a Window'
rmsWindow
)
