// 01_StartHere_LivePedalboardSuite.scd
// v0.6.2
// MD 20250928-1935

(
// Purpose
// - Bring up LivePedalboardSuite from a clean state (server reboot, GUI, MPB, CommandTree).
// - Enable GUI taps for overlay; HUD meters will be driven by “02_ForceMeters_FromBuses.scd”.
// Style
// - var-first; no server.sync; use s.waitForBoot; Server.default.bind; AppClock for UI.

var systemRef, windowRef;
var rebootServer, ensureAudioProxies, startSystem, findMagicDisplayWindow, frontWindow, afterBringUp;

rebootServer = {
    if(s.serverRunning) { s.reboot } { s.boot };
    s.waitForBoot({
        s.initTree;
        Server.default.bind({ s.defaultGroup.freeAll });
        "🔁 Server booted & tree initialized.".postln;
    });
};

ensureAudioProxies = {
    Server.default.bind({
        if(Ndef(\chainA).source.isNil) { Ndef(\chainA, { \in.ar(2) }) };
        if(Ndef(\chainB).source.isNil) { Ndef(\chainB, { \in.ar(2) }) };
        if(Ndef(\ts0   ).source.isNil) { Ndef(\ts0,    { Silent.ar(2) }) };
        if(Ndef(\testmelody).source.isNil) {
            Ndef(\testmelody, {
                var trig = Impulse.kr(2.4);
                var sel  = Demand.kr(trig, 0, Dwhite(0, 4, inf));
                var scale = [60, 62, 64, 67, 69];
                var f = Select.kr(sel, scale).midicps;
                var env = Decay2.kr(trig, 0.01, 0.35);
                var pan = LFNoise1.kr(0.35).range(-0.6, 0.6);
                Pan2.ar(SinOsc.ar(f) * env * 0.22, pan)
            });
        };
        Ndef(\chainA).ar(2); Ndef(\chainB).ar(2);
        Ndef(\ts0).ar(2);    Ndef(\testmelody).ar(2);
    });
};

startSystem = {
    systemRef = LivePedalboardSystem.new(nil);
    systemRef.bringUpAll; // PerfHUD if present; else GridDemo
    ~system = systemRef;
    ~mpb    = systemRef.pedalboard;
    ~gui    = systemRef.statusDisplay;
};

findMagicDisplayWindow = {
    Window.allWindows.detect({ |w|
        var nm = w.tryPerform(\name);
        nm.notNil and: { nm.asString.beginsWith("MagicDisplayGUI") }
    })
};

frontWindow = { |w| if(w.notNil) { AppClock.sched(0.0, { w.front; nil }) }; w };

afterBringUp = { |lps|
    if(lps.respondsTo(\installAdapterBridge)) { lps.installAdapterBridge };
    if(lps.respondsTo(\enableAutoMeters))     { lps.enableAutoMeters(24, 0.35) };  // GUI taps for overlay
    frontWindow.(findMagicDisplayWindow.());
};

rebootServer.value;
ensureAudioProxies.value;
startSystem.value;
windowRef = afterBringUp.(systemRef);
windowRef
)
