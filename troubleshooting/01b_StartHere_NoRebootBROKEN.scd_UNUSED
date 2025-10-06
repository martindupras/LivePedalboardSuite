// 01b_StartHere_NoReboot.scd
// v0.6.3
// MD 20250929-11:46

(
// Purpose
// - Bring up LivePedalboardSuite when the server is already running (beep booted it).
// - Avoid reboot races; opens the single GUI window; enables GUI taps.
// - Force GridDemo for these tests (PerfHUD pulses and lacks setOperations).
// Style
// - var-first; no server.sync; Server.default.bind; AppClock for UI.

var systemRef, windowRef, pedalboardRef, guiRef;
var ensureAudioProxies, startSystem, findMagicDisplayWindow, closeMagicDisplayWindows;
var installGridDemo, bindDisplay, afterBringUp;

// ---------- helpers ----------

ensureAudioProxies = {
    Server.default.bind({
        if(Ndef(\chainA).source.isNil) { Ndef(\chainA, { \in.ar(2) }) };
        if(Ndef(\chainB).source.isNil) { Ndef(\chainB, { \in.ar(2) }) };
        if(Ndef(\ts0).source.isNil)    { Ndef(\ts0,    { Silent.ar(2) }) };
        if(Ndef(\testmelody).source.isNil) {
            Ndef(\testmelody, { // neutral; 02D will replace with centered pulses
                var trig = Impulse.kr(2.4);
                var sel  = Demand.kr(trig, 0, Dwhite(0, 4, inf));
                var scale = [60, 62, 64, 67, 69];
                var f = Select.kr(sel, scale).midicps;
                var env = Decay2.kr(trig, 0.01, 0.35);
                Pan2.ar(SinOsc.ar(f) * env * 0.22, 0.0)
            });
        };
        Ndef(\chainA).ar(2); Ndef(\chainB).ar(2);
        Ndef(\ts0).ar(2);    Ndef(\testmelody).ar(2);
    });
};

findMagicDisplayWindow = {
    Window.allWindows.detect({ |w|
        var nm = w.tryPerform(\name);
        nm.notNil and: { nm.asString.beginsWith("MagicDisplayGUI") }
    })
};

closeMagicDisplayWindows = {
    var wins = Window.allWindows.select({ |w|
        var nm = w.tryPerform(\name) ? "";
        nm.asString.beginsWith("MagicDisplayGUI")
    });
    AppClock.sched(0.00, { wins.do(_.close); nil });
};

installGridDemo = {
    // Create GridDemo and publish it
    AppClock.sched(0.05, {
        guiRef = MagicDisplayGUI_GridDemo.new;        // <- concrete GUI
        ~gui   = guiRef;                               // publish for step scripts
        // if LPS carries the variable, update it too (it’s a <> ivar, settable)
        if(systemRef.notNil and: { systemRef.respondsTo(\statusDisplay_) }) {
            systemRef.statusDisplay_(guiRef);
        };
        // bind display to pedalboard if possible
        bindDisplay.value;
        // meters off->on to ensure responders
        if(guiRef.respondsTo(\enableMeters)) { guiRef.enableMeters(false); guiRef.enableMeters(true) };
        guiRef.showExpectation("System ready.", 0);
        guiRef.window.front.alwaysOnTop_(true);
        nil
    });
};

bindDisplay = {
    pedalboardRef = systemRef.pedalboard;
    if(pedalboardRef.notNil and: { pedalboardRef.respondsTo(\setDisplay) } and: { guiRef.notNil }) {
        pedalboardRef.setDisplay(guiRef);
    };
};

startSystem = {
    if(s.serverRunning.not) { "⚠️ Server not running; run 03_Sanity_Beep first.".postln };
    systemRef = LivePedalboardSystem.new(nil);
    systemRef.bringUpAll;            // this may load PerfHUD if present
    ~system = systemRef;
    ~mpb    = systemRef.pedalboard;
    // Note: when PerfHUD is used, statusDisplay stays nil; we’ll force GridDemo next.
};

afterBringUp = { |lps|
    // Route short canonicals via adapter + post-switch meter re-arm
    if(lps.respondsTo(\installAdapterBridge)) { lps.installAdapterBridge };
    if(lps.respondsTo(\enableAutoMeters))     { lps.enableAutoMeters(24, 0.35) };

    // If PerfHUD window was created, close it and switch to GridDemo
    AppClock.sched(0.05, {
        var win = findMagicDisplayWindow.();
        // If bringUpAll used PerfHUD, LivePedalboardSystem.statusDisplay is nil.
        if(lps.statusDisplay.isNil) {
            // Close the PerfHUD window (title contains "Performance HUD")
            if(win.notNil and: { win.name.asString.contains("Performance HUD") }) { win.close };
            installGridDemo.value; // create GridDemo, publish ~gui, bind to pedalboard
        } {
            // We already have a GUI object (GridDemo path)
            guiRef = lps.statusDisplay; ~gui = guiRef; bindDisplay.value;
            guiRef.window.front.alwaysOnTop_(true);
        };
        nil
    });
};

// ---------- run ----------

ensureAudioProxies.value;
startSystem.value;       // creates LPS + MPB; may open PerfHUD
closeMagicDisplayWindows.value;  // ensure only one window survives (we’ll reinstall)
afterBringUp.(systemRef);
)
