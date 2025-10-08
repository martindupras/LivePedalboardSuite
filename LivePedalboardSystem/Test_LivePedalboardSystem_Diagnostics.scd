// Test_LivePedalboardSystem_Diagnostics.scd
// v0.0.1
// MD 20251008-1402

/* Purpose
- Exercise LivePedalboardSystem without touching your main project graph.
- Confirm class presence, method availability, GUI open, and /peakrmsA feed.
Style
- Single block; var-first in every block; descriptive lowercase names; no server.sync.
- Server ops inside Server.default.bind; GUI actions on AppClock.
- Returns '-> a Window' when the LPDisplay window is open; nil on hard failure.
*/

(
var s, cls, lpb, win;
var passCount, failCount, warnCount;
var results;
var ok, fail, warn, info;
var methodsNeeded, methodsMissing, canRunBringUpAll;
var enableConsoleMeters, injectAudio, pulseSeconds;
var makeHudFriendly;

// -------------------- configuration knobs --------------------
enableConsoleMeters = true;   // briefly print LPDisplay meter lines
injectAudio         = true;   // briefly route a safe pink-noise pulse to A
pulseSeconds        = 2.0;    // how long the pulse runs
makeHudFriendly     = true;   // apply your preferred HUD map (-6 dB top, -60 floor)

// -------------------- helpers --------------------
passCount = 0; failCount = 0; warnCount = 0;
results = List.new;
ok   = { |msg| ("[OK] "   ++ msg).postln; passCount = passCount + 1; results.add("[OK] "   ++ msg) };
fail = { |msg| ("[FAIL] " ++ msg).warn;   failCount = failCount + 1; results.add("[FAIL] " ++ msg) };
warn = { |msg| ("[WARN] " ++ msg).postln; warnCount = warnCount + 1; results.add("[WARN] " ++ msg) };
info = { |msg| ("[INFO] " ++ msg).postln; results.add("[INFO] " ++ msg) };

// -------------------- banner --------------------
"============================================================".postln;
"LivePedalboardSystem :: DIAGNOSTICS".postln;
"============================================================".postln;

// -------------------- server readiness (no server.sync) --------------------
s = Server.default;
if(s.serverRunning.not) {
    info.value("Booting default server...");
    s.waitForBoot({
        s.initTree;
        ok.value("Server booted and node tree initialised.");
    });
} {
    ok.value("Server already running.");
};

// -------------------- class presence --------------------
cls = \LivePedalboardSystem.asClass;
if(cls.isNil) {
    fail.value("LivePedalboardSystem class not found. Put the class in Extensions and recompile.");
    ^nil
} {
    ok.value("LivePedalboardSystem class is compiled.");
};

// -------------------- required/optional methods footprint --------------------
lpb = cls.new;

// required for this test
methodsNeeded = [
    \bringUpMagicDisplayGUI,    // must exist for window open test
    \refreshDisplay             // used later if available
];

// warn if any of the bringUpAll dependencies are missing (we won't run bringUpAll unless complete)
methodsMissing = IdentitySet.new;
[
    \ensureServerReady,
    \bringUpPedalboard,
    \bringUpCommandSystem,
    \installAdapterBridge,
    \enableAutoMeters,
    \ensureLogger,
    \logInfo,
    \bringUpAll
].do { |sym|
    if(lpb.respondsTo(sym).not) { methodsMissing.add(sym) }
};

methodsNeeded.do { |sym|
    if(lpb.respondsTo(sym)) { ok.value("Method present: " ++ sym.asString) } { fail.value("Method missing: " ++ sym.asString) };
};

if(methodsMissing.isEmpty) {
    ok.value("Full bringUpAll dependency set is present.");
    canRunBringUpAll = true;
} {
    warn.value("bringUpAll not executed; missing: " ++ methodsMissing.asArray.collect(_.asString).join(", "));
    canRunBringUpAll = false;
};

// -------------------- open the display via the class --------------------
win = lpb.bringUpMagicDisplayGUI; // -> a Window on success
if(win.isNil or: { win.class !== Window }) {
    fail.value("bringUpMagicDisplayGUI did not return -> a Window.");
    ^nil
} {
    ok.value("bringUpMagicDisplayGUI returned -> a Window.");
};

// apply HUD preferences & quiet console (we may temporarily re-enable it below)
if(makeHudFriendly and: { lpb.tryPerform(\lpDisplay).notNil }) {
    lpb.lpDisplay.setHudMap(LPDisplayHudMap.new(-6, -60, 1.0));
    lpb.lpDisplay.setConsoleLevelsOn(false);
    ok.value("HUD mapping applied (-6 dB top, -60 dB floor, gamma 1.0) and console meters off.");
};

// status display adapter check
if(lpb.tryPerform(\statusDisplay).notNil) {
    ok.value("statusDisplay adapter is present (LPDisplayAdapter).");
} {
    warn.value("statusDisplay adapter is nil (not critical for this test).");
};

// -------------------- optional full bring-up --------------------
if(canRunBringUpAll) {
    info.value("Running bringUpAll (full system bring-up)...");
    // This calls ensureServerReady, bringUpPedalboard, bringUpCommandSystem, installAdapterBridge, enableAutoMeters, refreshDisplay, ensureLogger, logInfo
    win = lpb.bringUpAll; // -> a Window
    if(win.notNil and: { win.class === Window }) {
        ok.value("bringUpAll returned -> a Window.");
    } {
        warn.value("bringUpAll did not return a Window (continuing).");
    };
} {
    info.value("Skipping bringUpAll (dependencies missing).");
};

// -------------------- refresh display if available --------------------
if(lpb.respondsTo(\refreshDisplay)) {
    lpb.refreshDisplay;
    ok.value("refreshDisplay executed.");
} {
    warn.value("refreshDisplay is not available.");
};

// -------------------- (optional) console meters + audio pulse to A --------------------
if(enableConsoleMeters and: { lpb.tryPerform(\lpDisplay).notNil }) {
    lpb.lpDisplay.setConsoleLevelsOn(true);
    info.value("LPDisplay console levels ENABLED (expect A-level dB lines briefly).");
};

if(injectAudio) {
    Server.default.bind({
        // self-contained diagnostic chain, isolated names
        Ndef(\lps_diag_meterA, {
            var inSig = \in.ar(0!2);
            SendPeakRMS.kr(inSig, 20, 3, '/peakrmsA', 2001); // A id = 2001
            inSig
        });
        Ndef(\lps_diag_src, {
            PinkNoise.ar(1 ! 2) * \amp.kr(0.12).clip(0.0, 1.0)
        });
        Ndef(\lps_diag_sinkA, { \in.ar(0!2) });
        Ndef(\lps_diag_sinkA) <<> Ndef(\lps_diag_meterA) <<> Ndef(\lps_diag_src);

        // play the pulse
        Ndef(\lps_diag_sinkA).play;
        ok.value("Injected pink-noise pulse into /peakrmsA via lps_diag_* chain.");
    });

    AppClock.sched(pulseSeconds, {
        Ndef(\lps_diag_sinkA).stop;
        if(lpb.tryPerform(\lpDisplay).notNil) {
            lpb.lpDisplay.setConsoleLevelsOn(false);
            info.value("LPDisplay console levels DISABLED.");
        };
        nil
    });
};

// -------------------- summary & return --------------------
"------------------------------------------------------------".postln;
("Diagnostics summary: " ++ passCount.asString ++ " OK, " ++ warnCount.asString ++ " WARN, " ++ failCount.asString ++ " FAIL.").postln;
"------------------------------------------------------------".postln;

// Bring the window to front and return it (-> a Window)
AppClock.sched(0.0, { win.front; nil });
win
)