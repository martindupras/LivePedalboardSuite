// StartHere_LivePedalboardSuite.scd
// v0.6.1
// MD 20250928-1824
//
// Purpose
// - Canonical bring-up for LivePedalboardSuite using ONE GUI with WORKING METERS.
// - Avoid duplicate GUI/taps: rely on LivePedalboardSystem.bringUpAll to open GUI,
//   then install the adapter bridge and auto-meters once.
//
// Style / Guard Rails
// - single () block; var-first; lowercase names; no server.sync; no non-local '^'.
// - UI via AppClock; server ops inside Server.default.bind when needed.
// - Returns -> a Window (MagicDisplayGUI…).

(
var meterRate, postSwitchDelay, systemRef, windowRef;
var findMagicDisplayWindow, closeExistingMagicDisplayWindows, frontWindow, afterBringUp;

// ---- tunables ----
meterRate = 24;
postSwitchDelay = 0.35;

// ---- helpers ----
closeExistingMagicDisplayWindows = {
    var windows, i, w, nameString;
    windows = Window.allWindows; i = 0;
    while { i < windows.size } {
        w = windows[i];
        nameString = w.tryPerform(\name);
        if(nameString.notNil and: { nameString.asString.beginsWith("MagicDisplayGUI") }) {
            w.close;
        };
        i = i + 1;
    };
};

findMagicDisplayWindow = {
    var win;
    win = Window.allWindows.detect({ |w|
        var nm = w.tryPerform(\name);
        nm.notNil and: { nm.asString.beginsWith("MagicDisplayGUI") }
    });
    win
};

frontWindow = { |w|
    if(w.notNil) {
        AppClock.sched(0.0, { w.front; nil });
    };
    w
};

afterBringUp = { |lps|
    // Adapter: route short canonical commands to MagicPedalboard (+HUD toggle on /switch)
    if(lps.respondsTo(\installAdapterBridge)) { lps.installAdapterBridge };
    // Meters: assert one set of taps + GUI re-arm (idempotent)
    if(lps.respondsTo(\enableAutoMeters)) { lps.enableAutoMeters(meterRate, postSwitchDelay) };
    // detect and front the GUI window
    frontWindow.(findMagicDisplayWindow.());
};

// ---- run ----

// 0) keep one GUI window only
closeExistingMagicDisplayWindows.();

// 1) shutdown existing system cleanly (if present)
if(~system.notNil and: { ~system.respondsTo(\shutdownAll) }) { ~system.shutdownAll };

// 2) construct and bring up everything (this will open the GUI once)
systemRef = LivePedalboardSystem.new(nil);
systemRef.bringUpAll;

// 3) post-steps: adapter bridge + meters + front window
windowRef = afterBringUp.(systemRef);

// 4) publish handles
~system = systemRef;
~mpb = systemRef.pedalboard;
~gui = systemRef.statusDisplay;

// 5) return the GUI window
windowRef
)
