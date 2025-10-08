// Test_LivePedalboardSystem_Diagnostics.scd
// v0.0.4
// MD 20251008-1420

/* Purpose
- Verify LivePedalboardSystem class + methods.
- Open LPDisplay via bringUpMagicDisplayGUI (-> a Window).
- Optional: run bringUpAll (opt-out by default to avoid competing /peakrmsA taps).
- Optional: inject a brief pink-noise pulse into /peakrmsA using isolated lps_diag_* Ndefs.
- Optional: quietPeek collects a few /peakrmsA frames and prints one summary line (no console spam).

Style
- Single block; var-first in every block; descriptive lowercase names; no server.sync.
- Server ops inside Server.default.bind; GUI actions on AppClock.
- Returns '-> a Window' via the last expression.
*/

(
var defaultServer, lpbClass, lpbSystem, displayWindow;
var passCount, failCount, warnCount, resultLines, hardFailure;
var postOk, postFail, postWarn, postInfo;
var methodsNeeded, missingForBringUpAll, canRunBringUpAll;

// -------------------- configuration --------------------
var config;
config = (
    runFullBringUp: false,   // default false to avoid AutoMeters installing competing taps
    injectAudio: true,       // inject a short pink-noise pulse to A
    pulseSeconds: 3.0,       // audible duration
    pulseAmp: 0.20,          // louder than before; keep safe
    makeHudFriendly: true,   // (-6, -60, 1.0)
    enableConsoleMeters: false, // keep LPDisplay console quiet by default
    quietPeekFrames: 10      // if >0, sample N frames from /peakrmsA via a temp OSCdef and print one line
);

// -------------------- init & helpers --------------------
passCount = 0; failCount = 0; warnCount = 0; hardFailure = false;
resultLines = List.new;

postOk = { |message| var nothing;
    ("[OK] "   ++ message).postln; passCount = passCount + 1; resultLines.add("[OK] "   ++ message)
};
postFail = { |message| var nothing;
    ("[FAIL] " ++ message).warn;   failCount = failCount + 1; resultLines.add("[FAIL] " ++ message)
};
postWarn = { |message| var nothing;
    ("[WARN] " ++ message).postln; warnCount = warnCount + 1; resultLines.add("[WARN] " ++ message)
};
postInfo = { |message| var nothing;
    ("[INFO] " ++ message).postln; resultLines.add("[INFO] " ++ message)
};

// -------------------- banner --------------------
"============================================================".postln;
"LivePedalboardSystem :: DIAGNOSTICS (quiet)".postln;
"============================================================".postln;

// -------------------- server readiness --------------------
defaultServer = Server.default;
if(defaultServer.serverRunning.not) {
    postInfo.value("Booting default server...");
    defaultServer.waitForBoot({
        var nothing;
        defaultServer.initTree;
        postOk.value("Server booted and node tree initialised.");
    });
} {
    postOk.value("Server already running.");
};

// -------------------- class presence --------------------
lpbClass = \LivePedalboardSystem.asClass;
if(lpbClass.isNil) {
    postFail.value("LivePedalboardSystem not found. Place the class under Extensions and recompile.");
    hardFailure = true;
} {
    postOk.value("LivePedalboardSystem class is compiled.");
};

// -------------------- required/optional methods footprint --------------------
if(hardFailure.not) {
    var methodSymbol;
    lpbSystem = lpbClass.new;

    methodsNeeded = [ \bringUpMagicDisplayGUI, \refreshDisplay ];

    missingForBringUpAll = IdentitySet.new;
    [ \ensureServerReady, \bringUpPedalboard, \bringUpCommandSystem,
      \installAdapterBridge, \enableAutoMeters, \ensureLogger,
      \logInfo, \bringUpAll ].do({ |symbol|
        var nothing;
        if(lpbSystem.respondsTo(symbol).not) { missingForBringUpAll.add(symbol) };
    });

    methodsNeeded.do({ |symbol|
        var nothing;
        if(lpbSystem.respondsTo(symbol)) { postOk.value("Method present: " ++ symbol.asString) } { postFail.value("Method missing: " ++ symbol.asString) };
    });

    if(missingForBringUpAll.isEmpty) {
        postOk.value("bringUpAll dependency set is present.");
        canRunBringUpAll = true;
    } {
        postWarn.value("bringUpAll will be skipped; missing: " ++ missingForBringUpAll.asArray.collect(_.asString).join(", "));
        canRunBringUpAll = false;
    };
};

// -------------------- open the display via the class --------------------
if(hardFailure.not) {
    displayWindow = lpbSystem.bringUpMagicDisplayGUI; // -> a Window
    if(displayWindow.notNil and: { displayWindow.class === Window }) {
        postOk.value("bringUpMagicDisplayGUI returned -> a Window.");
    } {
        postFail.value("bringUpMagicDisplayGUI did not return a Window.");
        hardFailure = true;
    };
};

// -------------------- HUD prefs & console quiet --------------------
if(hardFailure.not) {
    if(config[\makeHudFriendly] and: { lpbSystem.tryPerform(\lpDisplay).notNil }) {
        lpbSystem.lpDisplay.setHudMap(LPDisplayHudMap.new(-6, -60, 1.0));
        lpbSystem.lpDisplay.setConsoleLevelsOn(false);
        postOk.value("HUD mapping applied (-6 dB top, -60 dB floor, gamma 1.0); console meters OFF.");
    };

    if(lpbSystem.tryPerform(\statusDisplay).notNil) {
        postOk.value("statusDisplay adapter present (LPDisplayAdapter).");
    } {
        postWarn.value("statusDisplay adapter is nil (non-critical).");
    };
};

// -------------------- optional full bring-up (default: OFF to prevent meter collisions) --------------------
if(hardFailure.not and: { config[\runFullBringUp] and: { canRunBringUpAll } }) {
    postInfo.value("Running bringUpAll (you enabled this in config)...");
    displayWindow = lpbSystem.bringUpAll; // may install AutoMeters
    if(displayWindow.notNil and: { displayWindow.class === Window }) {
        postOk.value("bringUpAll returned -> a Window.");
    } {
        postWarn.value("bringUpAll did not return a Window (continuing).");
    };
} {
    var nothing;
    if(hardFailure.not and: { config[\runFullBringUp].not }) {
        postInfo.value("Skipping bringUpAll (keeping diagnostics isolated, no extra taps).");
    };
};

// -------------------- refresh display if available --------------------
if(hardFailure.not) {
    if(lpbSystem.respondsTo(\refreshDisplay)) {
        lpbSystem.refreshDisplay;
        postOk.value("refreshDisplay executed.");
    } {
        postWarn.value("refreshDisplay not available.");
    };
};

// -------------------- optional: very quiet peek of /peakrmsA --------------------
if(hardFailure.not and: { config[\quietPeekFrames] > 0 }) {
    var framesWanted, framesSeen, sumDb, oscName;
    framesWanted = config[\quietPeekFrames].asInteger.max(1);
    framesSeen = 0;
    sumDb = 0.0;
    oscName = \lps_diag_quietPeekA;

    OSCdef(oscName, { |msg, time, addr, recvPort|
        var nothing, peak, rms, db;
        // msg shape from SendPeakRMS.kr: ['/peakrmsA', id, peakL, peakR, rmsL, rmsR, ...] — we use RMS avg
        peak = ((msg[2] ? 0.0) + (msg[3] ? 0.0)) * 0.5;
        rms  = ((msg[4] ? 0.0) + (msg[5] ? 0.0)) * 0.5;
        db   = (rms <= 0.0000001).if({ -120.0 }, { 20.0 * log10(rms.max(1e-12)) });
        sumDb = sumDb + db;
        framesSeen = framesSeen + 1;
        if(framesSeen >= framesWanted) {
            var avgDb;
            avgDb = (sumDb / framesSeen);
            ("[PEEK] /peakrmsA avg over " ++ framesSeen.asString ++ " frames: " ++ avgDb.round(0.1).asString ++ " dB").postln;
            OSCdef(oscName).free;
        };
    }, '/peakrmsA');
};

// -------------------- optional: inject short pink-noise pulse to A (isolated names) --------------------
if(hardFailure.not and: { config[\injectAudio] }) {
    Server.default.bind({
        var meterInput, diagSig, sigIn;
        Ndef(\lps_diag_meterA, {
            var inSig;
            inSig = \in.ar(0!2);
            SendPeakRMS.kr(inSig, 20, 3, '/peakrmsA', 32001);
            inSig
        });
        Ndef(\lps_diag_src, {
            var src;
            src = PinkNoise.ar(1 ! 2) * \amp.kr(config[\pulseAmp]).clip(0.0, 1.0);
            src
        });
        Ndef(\lps_diag_sinkA, { var inSig; inSig = \in.ar(0!2); inSig });

        Ndef(\lps_diag_sinkA) <<> Ndef(\lps_diag_meterA) <<> Ndef(\lps_diag_src);
        Ndef(\lps_diag_sinkA).play;
    });
    postOk.value("Injected pink-noise pulse via lps_diag_* chain (A).");

    // Stop only the sink after the pulse; leave others idle to avoid n_set races.
    AppClock.sched(config[\pulseSeconds], {
        var nothing;
        Ndef(\lps_diag_sinkA).stop;
        if(lpbSystem.tryPerform(\lpDisplay).notNil) {
            if(config[\enableConsoleMeters]) {
                lpbSystem.lpDisplay.setConsoleLevelsOn(false);
                postInfo.value("LPDisplay console levels DISABLED.");
            };
        };
        nil
    });
};

// -------------------- summary & return --------------------
"------------------------------------------------------------".postln;
("Diagnostics summary: " ++ passCount.asString ++ " OK, " ++ warnCount.asString ++ " WARN, " ++ failCount.asString ++ " FAIL.").postln;
"------------------------------------------------------------".postln;

AppClock.sched(0.0, { var nothing; if(displayWindow.notNil) { displayWindow.front; }; nil });
displayWindow
)
