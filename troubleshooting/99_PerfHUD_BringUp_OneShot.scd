// 99_PerfHUD_BringUp_OneShot.scd
// v0.1.0
// MD 2025-09-29 14:25 BST

/* Purpose
 - Bring up (or focus) the PerfHUD window reliably with minimal moving parts.
 - Verify that meter data is arriving via OSC for a couple of seconds.
Style
 - var-first; AppClock-only for UI; no server.sync; idempotent; nil-safe.
Run
 - Run AFTER: 02S_AssertStereo_ChainAB_and_Retap_SAFE.scd
   (so taps are armed and /md/levels(_gui)/ampA/ampB are flowing).
*/

(
var perfHudPath, ensurePerfHUD, waitForWindow, startProbe, stopProbe;

// Path as seen in your logs
perfHudPath = (
    Platform.userExtensionDir
    ++ "/LivePedalboardSuite/MagicPedalboard/troubleshooting"
    ++ "/MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.4.scd"
).standardizePath;

// 1) Ensure PerfHUD is loaded; DO NOT close existing windows (avoid flicker/races)
ensurePerfHUD = {
    var existing;
    existing = Window.allWindows.detect({ |w|
        (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI")
    });
    if(existing.isNil) {
        if(File.exists(perfHudPath)) {
            "99: Loading PerfHUD…".postln;
            perfHudPath.load;
        }{
            ("99: PerfHUD file not found:\n" ++ perfHudPath).warn;
        };
    }{
        "99: PerfHUD already present; focusing…".postln;
    };
};

// 2) Wait for the MagicDisplayGUI window, bring to front + always-on-top
waitForWindow = { arg triesLeft = 40, thenDo = { } ;
    AppClock.sched(0.05, {
        var win;
        win = Window.allWindows.detect({ |w|
            (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI")
        });
        if(win.notNil) {
            win.front.alwaysOnTop_(true);
            ~perfHUDWin = win; // publish for convenience
            thenDo.value(win);
            nil
        }{
            if(triesLeft <= 0) { "99: PerfHUD window not found; giving up.".warn; nil }{
                waitForWindow.value(triesLeft - 1, thenDo);
            }
        }
    });
};

// 3) Brief OSC probe: confirm meter messages are arriving; auto-stops
startProbe = {
    if(~osc_probe.notNil) { ~osc_probe.free; ~osc_probe = nil };
    ~osc_probe = OSCdef(\perfHUD_probe, { |msg|
        var path = msg[0];
        if(
            path == '/md/levels'
            or: { path == '/md/levels_gui' }
            or: { path == '/ampA' }
            or: { path == '/ampB' }
        ) {
            ("[levels] " ++ path ++ " · size=" ++ msg.size).postln;
        };
    }, nil);
    "99: Probing /md/levels(_gui) & /ampA/B for 2 seconds…".postln;
    AppClock.sched(2.0, { stopProbe.value; nil });
};

stopProbe = {
    if(~osc_probe.notNil) { ~osc_probe.free; ~osc_probe = nil };
    "99: Probe stopped.".postln;
};

// —— RUN —— //
AppClock.sched(0.00, { ensurePerfHUD.value; nil });
AppClock.sched(0.10, { waitForWindow.value(40, { startProbe.value }); nil });
)
