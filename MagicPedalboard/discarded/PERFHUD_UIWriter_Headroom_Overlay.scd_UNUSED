// PERFHUD_UIWriter_Headroom_Overlay.scd
// v0.1.0
// MD 2025-09-29

(
var disableLegacyHudOsc, findPerfHudWindow, collectIndicatorsRecursively;
var bindMetersOnce, updateMetersFromModelMapped, startHudTicker;
var desiredFps, mappingExists, meterOrderNote;

// Desired HUD update cadence
desiredFps = 24.0;

// 1) Disable the legacy /md/levels HUD OSCdef so it cannot overwrite our mapped values
disableLegacyHudOsc = {
    var existingHudOsc, resultText;
    existingHudOsc = OSCdef.all.at(\md_levels_hud);
    if(existingHudOsc.notNil) {
        existingHudOsc.free;
        resultText = "[HUD] Disabled legacy OSCdef(\\md_levels_hud) for /md/levels to prevent raw 0..1 pegging.";
    }{
        resultText = "[HUD] Legacy OSCdef(\\md_levels_hud) not present (nothing to disable).";
    };
    resultText.postln;
    nil
};

// 2) Utilities to find the PerfHUD window and collect all LevelIndicators
findPerfHudWindow = {
    var perfWindow;
    perfWindow = Window.allWindows.detect({ arg eachWindow;
        var windowNameString;
        windowNameString = (eachWindow.tryPerform(\name) ? "").asString;
        windowNameString.beginsWith("MagicDisplayGUI")
    });
    perfWindow
};

collectIndicatorsRecursively = { arg rootView;
    var allIndicators, recurseChildren;
    allIndicators = List.new;
    recurseChildren = { arg viewToScan;
        if(viewToScan.isKindOf(LevelIndicator)) { allIndicators.add(viewToScan) };
        viewToScan.children.do({ arg childView; recurseChildren.(childView) });
    };
    recurseChildren.(rootView);
    allIndicators.asArray
};

// 3) Cache references to the first 4 meters (A L, A R, B L, B R)
//    Adjust here if your layout uses a different order or more meters.
bindMetersOnce = {
    var perfWindow, rootView, allMeters, bindOk;
    bindOk = false;

    perfWindow = findPerfHudWindow.();
    if(perfWindow.isNil) {
        "PerfHUD window not found (MagicDisplayGUI...). Will retry.".warn;
    }{
        rootView = perfWindow.tryPerform(\view);
        if(rootView.isNil) {
            "PerfHUD host view missing. Will retry.".warn;
        }{
            allMeters = collectIndicatorsRecursively.(rootView);
            if(allMeters.size < 4) {
                ("[HUD] Found only " ++ allMeters.size ++ " LevelIndicators; expecting ≥ 4. Will retry.").warn;
            }{
                // Cache the first four meters (override if you have a specific order)
                ~hud_meterA_left   = allMeters[0];
                ~hud_meterA_right  = allMeters[1];
                ~hud_meterB_left   = allMeters[2];
                ~hud_meterB_right  = allMeters[3];

                meterOrderNote = "[HUD] Bound meters: [0]=A_L  [1]=A_R  [2]=B_L  [3]=B_R (override if your layout differs)";
                meterOrderNote.postln;
                bindOk = true;
            };
        };
    };
    bindOk
};

// 4) Mapped update from model → LevelIndicators
updateMetersFromModelMapped = {
    var levelsA, levelsB;
    var mappedAL, mappedAR, mappedBL, mappedBR;

    // Ensure mapping helper exists (installed by your responders extender file)
    mappingExists = (~hud_map_linear_to_ui.notNil);
    if(mappingExists.not) {
        "⚠️ ~hud_map_linear_to_ui is not defined. Evaluate MagicDisplayGUI_PerfHUD_MeterResponders_Ext.scd first.".warn;
        ^nil;
    };

    // Pull linear A/B pairs from model; default to zeros
    levelsA = ~md_levelsById.atFail(2001, { [0.0, 0.0] });
    levelsB = ~md_levelsById.atFail(2002, { [0.0, 0.0] });

    // Map linear (0..1) → UI value (0..1) using your headroom + gamma
    mappedAL = ~hud_map_linear_to_ui.(levelsA[0]);
    mappedAR = ~hud_map_linear_to_ui.(levelsA[1]);
    mappedBL = ~hud_map_linear_to_ui.(levelsB[0]);
    mappedBR = ~hud_map_linear_to_ui.(levelsB[1]);

    // Assign to cached meters (guards in case binding failed)
    if(~hud_meterA_left.notNil)   { ~hud_meterA_left.value   = mappedAL };
    if(~hud_meterA_right.notNil)  { ~hud_meterA_right.value  = mappedAR };
    if(~hud_meterB_left.notNil)   { ~hud_meterB_left.value   = mappedBL };
    if(~hud_meterB_right.notNil)  { ~hud_meterB_right.value  = mappedBR };
    nil
};

// 5) Start/replace one AppClock ticker that updates HUD at desiredFps
startHudTicker = {
    var makeTicker;

    // Stop a previous ticker if present
    if(~hud_tickerRoutine.notNil) {
        ~hud_tickerRoutine.stop;
        ~hud_tickerRoutine = nil;
        "[HUD] Replaced previous HUD ticker.".postln;
    };

    makeTicker = {
        ~hud_tickerRoutine = Routine({
            var waitSeconds;
            waitSeconds = 1.0 / desiredFps;
            while({ true }) {
                updateMetersFromModelMapped.();
                waitSeconds.yield;
            }
        });
        ~hud_tickerRoutine.play(AppClock);
        ("[HUD] HUD ticker active @ " ++ desiredFps.round(0.1) ++ " fps.").postln;
        nil
    };

    makeTicker.();
};

// Execute overlay
AppClock.sched(0.0, {
    var bound;
    disableLegacyHudOsc.();
    bound = bindMetersOnce.();
    if(bound.not) {
        // try again shortly in case the window just spawned
        AppClock.sched(0.25, {
            if(bindMetersOnce.()) { startHudTicker.() }{ "[HUD] Binding failed again; run this block once the HUD window is visible.".warn };
            nil
        });
    }{
        startHudTicker.();
    };
    nil
});
)
