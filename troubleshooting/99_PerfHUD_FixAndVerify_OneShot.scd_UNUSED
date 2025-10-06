// 99_PerfHUD_FixAndVerify_OneShot.scd
// v0.2.0
// MD 2025-09-29 14:32 BST

/* Purpose
 - One-shot: make the existing PerfHUD window show MOVING METERS, highlight ACTIVE chain,
   and prove pane text updates, without closing windows or touching audio routing.
 - Bridges /md/levels → also emit /md/levels_gui + /ampA + /ampB on the language port,
   so PerfHUD will update regardless of which path it is listening to internally.
 - Writes demo text via common GUI hooks (if exposed by PerfHUD’s compat shim).
Style
 - var-first; AppClock-only for UI; no server.sync; idempotent; nil-safe; no caret-returns.
Run
 - Run AFTER: 02S_AssertStereo_ChainAB_and_Retap_SAFE.scd (taps armed).
Flip
 - Set wantB=true to highlight NEXT (B) instead of CURRENT (A).
*/

(
var wantB;
var perfHudPath, ensurePerfHUD, waitForGui, setHighlight, pushDemoText;
var installBridges, freeBridges, bridgeLevelsToGuiAndAmp, mkLocalSender, probeStart, probeStop;

// ===== CONFIG =====
wantB = false; // false = highlight A; true = highlight B

// ===== PATH to PerfHUD script (from your logs) =====
perfHudPath = (
    Platform.userExtensionDir
    ++ "/LivePedalboardSuite/MagicPedalboard/troubleshooting"
    ++ "/MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.4.scd"
).standardizePath;

// ===== HELPERS =====

mkLocalSender = {
    var addr;
    addr = NetAddr("127.0.0.1", NetAddr.langPort);
    ^addr
};

// 1) Ensure PerfHUD exists; DO NOT close existing GUI (avoid flicker/race).
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
        existing.front.alwaysOnTop_(true);
    };
};

// 2) Wait until a GUI handle is usable.
//    PerfHUD usually installs a ~gui compat shim; if not, we still proceed with window only.
waitForGui = { arg triesLeft = 40, thenDo = { } ;
    AppClock.sched(0.05, {
        var win, ok;
        win = Window.allWindows.detect({ |w|
            (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI")
        });
        // Accept either ~gui controller (preferable) or at least the window
        ok = (win.notNil) and: { (~gui.notNil) or: { true } };
        if(ok) {
            if(~gui.isNil) {
                // Try to capture a compat controller if PerfHUD exposed one (harmless if not)
                ~gui = ~gui ?? { nil };
            };
            win.front.alwaysOnTop_(true);
            thenDo.value;
            nil
        }{
            if(triesLeft <= 0) { "99: PerfHUD window not ready; giving up.".warn; nil }
            { waitForGui.value(triesLeft - 1, thenDo) }
        }
    });
};

// 3) Highlight ACTIVE chain (default A). If compat shim exposes highlightCurrentColumn, use it.
setHighlight = {
    var targetSym;
    targetSym = (wantB.not).if({ \chainA }, { \chainB });
    if(~gui.notNil and: { ~gui.respondsTo(\highlightCurrentColumn) }) {
        ~gui.highlightCurrentColumn(targetSym);
        ("99: highlight set via GUI method → " ++ targetSym.asString).postln;
    }{
        // fallback: post only; we avoid direct view hacking in PerfHUD for safety
        ("99: highlight method not found (GUI compat shim missing?) — expected " ++ targetSym.asString).warn;
    };
};

// 4) Push DEMO TEXT: try showExpectation → updateTextField → setOperations (if present).
pushDemoText = {
    var stateText, lines;
    stateText = (wantB.not).if({ "Mode: test · ACTIVE=A" }, { "Mode: test · ACTIVE=B" });
    lines = ["fret 3 → add", "fret 5 → timebased", "fret 7 → modulation", "fret 9 → filter"];

    if(~gui.notNil and: { ~gui.respondsTo(\showExpectation) }) {
        ~gui.showExpectation(stateText, 0);
        "99: showExpectation OK".postln;
    }{
        if(~gui.notNil and: { ~gui.respondsTo(\updateTextField) }) {
            ~gui.updateTextField(\state, stateText);
            "99: updateTextField(:state) OK".postln;
        }{
            "99: No text API found on GUI (skipping)".warn;
        };
    };
    if(~gui.notNil and: { ~gui.respondsTo(\setOperations) }) {
        ~gui.setOperations(lines);
        "99: setOperations OK".postln;
    }{
        "99: setOperations not available (skipping choices text)".postln;
    };
};

// 5) Bridge /md/levels → also emit /md/levels_gui and /ampA/B so PerfHUD meters move.
freeBridges = {
    if(~osc_bridge_levels.notNil) { ~osc_bridge_levels.free; ~osc_bridge_levels = nil };
    if(~osc_bridge_gui.notNil)    { ~osc_bridge_gui.free; ~osc_bridge_gui    = nil };
};
bridgeLevelsToGuiAndAmp = {
    var out, lastPrint;
    var routeA, routeB;

    out = mkLocalSender.value;
    lastPrint = 0.0;

    // Helper to emit ampA/ampB from 4 floats [lA, rA, lB, rB]
    routeA = { arg lA = 0.0, rA = 0.0; out.sendMsg('/ampA', 0, lA, rA) };
    routeB = { arg lB = 0.0, rB = 0.0; out.sendMsg('/ampB', 0, lB, rB) };

    // Bridge from /md/levels → duplicate as /md/levels_gui and /ampA/B
    ~osc_bridge_levels = OSCdef(\md_bridge_levels, { |msg, time, addr, recvPort|
        var floats, lA, rA, lB, rB;
        floats = msg.select({ |x| x.isNumber }).collect(_.asFloat);

        // Emit a straight pass-through for GUI path (same payload except the path)
        out.sendMsg('/md/levels_gui', *floats);

        // Try to extract last 4 floats as [lA, rA, lB, rB]; fallback to mean pairs if shorter
        if(floats.size >= 4) {
            lA = floats.at(floats.size - 4); rA = floats.at(floats.size - 3);
            lB = floats.at(floats.size - 2); rB = floats.at(floats.size - 1);
        }{
            lA = (floats.first ? 0.0); rA = (floats.drop(1).first ? lA);
            lB = lA; rB = rA;
        };
        routeA.value(lA.clip(0,1), rA.clip(0,1));
        routeB.value(lB.clip(0,1), rB.clip(0,1));

        // Throttled console confirmation
        if((SystemClock.seconds - lastPrint) > 0.50) {
            ("99: bridged levels → GUI + ampA/B   A=(" ++ lA.round(0.01) ++ "," ++ rA.round(0.01)
              ++ ")  B=(" ++ lB.round(0.01) ++ "," ++ rB.round(0.01) ++ ")").postln;
            lastPrint = SystemClock.seconds;
        };
    }, '/md/levels');

    // Also, if someone else sends /md/levels_gui only, mirror to ampA/B as well.
    ~osc_bridge_gui = OSCdef(\md_bridge_gui, { |msg|
        var floats, lA, rA, lB, rB;
        floats = msg.select({ |x| x.isNumber }).collect(_.asFloat);
        if(floats.size >= 4) {
            lA = floats.at(floats.size - 4); rA = floats.at(floats.size - 3);
            lB = floats.at(floats.size - 2); rB = floats.at(floats.size - 1);
            routeA.value(lA.clip(0,1), rA.clip(0,1));
            routeB.value(lB.clip(0,1), rB.clip(0,1));
        };
    }, '/md/levels_gui');

    "99: bridges installed (levels → gui + ampA/B)".postln;
};

// 6) Short probe: print any arriving meter messages for visibility (auto-stop)
probeStart = {
    if(~osc_probe.notNil) { ~osc_probe.free; ~osc_probe = nil };
    ~osc_probe = OSCdef(\md_probe_any, { |msg|
        var p = msg[0];
        if(p == '/md/levels' or: { p == '/md/levels_gui' } or: { p == '/ampA' } or: { p == '/ampB' }) {
            ("[probe] " ++ p ++ " size=" ++ msg.size).postln;
        };
    }, nil);
    "99: probe: watching /md/levels(_gui) & /ampA/B for 2s…".postln;
    AppClock.sched(2.0, { probeStop.value; nil });
};
probeStop = {
    if(~osc_probe.notNil) { ~osc_probe.free; ~osc_probe = nil };
    "99: probe stopped.".postln;
};

// 7) Uninstall bridges if you need to revert
~hud_fix_stop = {
    freeBridges.value;
    probeStop.value;
    "99: bridges and probe removed.".postln;
};

// ===== RUN (guarded) =====

AppClock.sched(0.00, { ensurePerfHUD.value; nil });
AppClock.sched(0.10, {
    waitForGui.value(40, {
        setHighlight.value;
        pushDemoText.value;
        freeBridges.value;
        installBridges.value;  // forward-declare call — see below
        probeStart.value;
        nil
    });
    nil
});

// We bind the bridge installer late to avoid forward-ref warnings in some editors
installBridges = { bridgeLevelsToGuiAndAmp.value };
)
