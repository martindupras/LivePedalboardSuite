// 01b_StartHere_NoReboot.scd
// v0.6.2
// MD 20250929-0918

(
// Purpose
// - Bring up LivePedalboardSuite when the server is already running (beep booted it).
// - Avoids reboot races; opens the single GUI window; enables GUI taps.
// Style
// - var-first; no server.sync; Server.default.bind; AppClock for UI.

var systemRef, windowRef;
var ensureAudioProxies, startSystem, findMagicDisplayWindow, frontWindow, afterBringUp;

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
    if(lps.respondsTo(\enableAutoMeters))     { lps.enableAutoMeters(24, 0.35) };
    frontWindow.(findMagicDisplayWindow.());
};

//new
~gui = Window.allWindows.detect { |w| w.name.asString.beginsWith("MagicDisplayGUI") };

ensureAudioProxies.value;
startSystem.value;
windowRef = afterBringUp.(systemRef);
windowRef
)
