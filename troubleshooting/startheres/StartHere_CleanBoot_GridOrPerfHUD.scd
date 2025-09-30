// StartHere_CleanBoot_GridOrPerfHUD.scd
// v0.1.0
// MD timestamp: 2025-09-26 16:13 GMT+1

/*
Purpose
- Clean boot pathway that brings up PerfHUD (guarded) and, if it fails, falls back to GridDemo.
- Ensures taps are running via LivePedalboardSystem-Taps_Stable.sc.
- Returns -> a Window (PerfHUD if healthy, otherwise Grid).

Style / Guard Rails
- Single () block; VAR-FIRST; no non-local returns; no server.sync.
- AppClock use is inside called files only; this wrapper remains finite.
- Loud console banners; prefer existing files; safe operations via Server.default.bind.
*/

(
var server, suitePath, stopDiagPath, perfhudPath, tapsPath, gridPath, gridMinPath;
var windowResult, banner, runFile, fallbackDone, fallbackWindow;

server = Server.default;
suitePath = Platform.userExtensionDir +/+ "LivePedalboardSuite";

stopDiagPath = suitePath +/+ "utilities/MD_Stop_All_MeterDiagnostics.scd";
perfhudPath  = suitePath +/+ "MagicPedalboard/troubleshooting/MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.4.scd";
/*tapsPath     = suitePath +/+ "LivePedalboardSystem/LivePedalboardSystem-Taps_Stable.sc";*/
tapsPath = suitePath +/+ "troubleshooting/startheres/Taps_Stable_Runtime_Shim.scd";

gridPath     = suitePath +/+ "MagicPedalboard/MagicDisplayGUI_GridDemo.sc";
gridMinPath  = suitePath +/+ "utilities/MD_MinBringUp_FeedA_SimpleMeters_GridDemo.scd";

banner = { arg text; ("[MPB-START] " ++ text).postln; };

runFile = { arg filePath;
    var exists, result;
    exists = File.exists(filePath);
    exists.if({
        ("[RUN] " ++ filePath).postln;
        result = thisProcess.interpreter.executeFile(filePath);
        ("[OK ] " ++ filePath).postln;
    }, {
        ("[MISS] " ++ filePath).warn;
        result = nil;
    });
    result
};

banner.("Clean boot begin — ensuring server and quiescent diagnostics…");

server.boot;
server.waitForBoot({
    Server.default.bind({
        server.initTree;
        server.defaultGroup.freeAll;
    });
});

runFile.(stopDiagPath);

banner.("PerfHUD bring-up (guarded) …");
windowResult = runFile.(perfhudPath);

// Always start taps; if missing, we still continue to Grid fallback.
runFile.(tapsPath);

// If PerfHUD did not return a Window, fall back to Grid.
(windowResult.isKindOf(Window)).if({
    banner.("PerfHUD window active — returning PerfHUD.");
    windowResult
}, {
    banner.("PerfHUD did not yield a Window — falling back to Grid…");
    fallbackDone = false;
    fallbackWindow = runFile.(gridPath);
    (fallbackWindow.isKindOf(Window)).if({
        fallbackDone = true;
        banner.("GridDemo is active — returning Grid window.");
        fallbackWindow
    }, {
        // Try minimal grid bring-up
        fallbackWindow = runFile.(gridMinPath);
        (fallbackWindow.isKindOf(Window)).if({
            fallbackDone = true;
            banner.("Minimal GridDemo is active — returning Grid window.");
            fallbackWindow
        }, {
            // As a last resort, create a tiny placeholder window so we still return -> a Window.
            banner.("All bring-up files missing or failed — creating placeholder window.");
            Window("MagicDisplayGUI (Placeholder)", Rect(120, 120, 480, 260)).front;
        });
    });
});
)
