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
