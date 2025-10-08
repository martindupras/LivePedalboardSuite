// PedalboardStarter.scd
// v0.1.1
// MD 20251008-1201

/*
Purpose
- Clean boot + single-window bring-up using LPDisplayLayoutWindow with A/B chains (JITLib Ndefs).
- Generated test source only (no SoundIn) for predictable, repeatable audio.
- Level taps *inside* the chain graphs send OSC to /peakrmsA and /peakrmsB for LPDisplay.
- Manual helpers are provided to switch A/B audibility (MIDI deferred for now).

Style / Guards
- One single block; var declarations first; lowercase identifiers; no server.sync; no non-local returns.
- GUI uses AppClock only (LPDisplay manages its own refresh if needed).
- JITLib routing via .source; audible switching via Ndef(\chainX).play/stop (do not use isPlaying).
- Returns '-> a Window' at the end.
*/

(
var displayLayoutWindow, topWindow, hudMapFunction;
var setupServer, closeExistingLpDisplayWindows, findWindowByPrefix;
var setupAudioGraphs, openDisplayWindow, switchToChainA, switchToChainB;

"==================== PedalboardStarter (v0.1) ====================".postln;

// --- boot to a known state ---
setupServer = {
    s.waitForBoot({
        Server.default.bind({
            "Audio outputs: %".format(s.options.numOutputBusChannels).postln;
            s.initTree;
            s.defaultGroup.freeAll;
        });
    });
};

// --- enforce a single LPDisplay window ---
closeExistingLpDisplayWindows = {
    Window.allWindows.do({ |w|
        var name;
        name = w.name.asString;
        if(name.beginsWith("LPDisplay")) { w.close };
    });
};

// --- find a window by prefix (so we can return -> a Window) ---
findWindowByPrefix = { |prefixStr|
    Window.allWindows.detect({ |w| w.name.asString.beginsWith(prefixStr.asString) })
    ?? { Window.allWindows.last };
};

// --- A/B chains with in-graph level taps (generated audio only) ---
setupAudioGraphs = {
    // Test source: stereo sine (audible), modest level.
    Ndef(\src).source = { SinOsc.ar([220, 221]) * 0.2 };

    // Chain A (audible by default)
    Ndef(\chainA).source = {
        var signal, mono, ampLin;
        signal = Ndef.ar(\src);                 // stereo
        mono   = Mix.new(signal);               // mono for measurement
        // Simple in-graph meter: ~10 Hz updates -> /peakrmsA with linear amplitude
        ampLin = Amplitude.kr(mono, 0.01, 0.3).clip(0.0, 1.0);
        SendReply.kr(Impulse.kr(10), "/peakrmsA", [ampLin]);
        signal;                                 // pass-through audio
    };

    // Chain B (initially silent by stopped state)
    Ndef(\chainB).source = {
        var signal, mono, ampLin;
        signal = Ndef.ar(\src);
        mono   = Mix.new(signal);
        ampLin = Amplitude.kr(mono, 0.01, 0.3).clip(0.0, 1.0);
        SendReply.kr(Impulse.kr(10), "/peakrmsB", [ampLin]);
        signal;
    };

    // Audible state: A=true, B=false (use play/stop; do not rely on isPlaying)
    Ndef(\chainA).play;
    Ndef(\chainB).stop;

    "Audio graphs ready: ChainA=play, ChainB=stop".postln;
};

// --- LPDisplay bring-up and meter wiring ---
openDisplayWindow = {
    var prefix;
    closeExistingLpDisplayWindows.();

    // Headroom map: top -6 dB, floor -60 dB, gamma 1.0 (linear-ish UI)
    hudMapFunction = { |linear|
        var safeLin, db, ui, topDb, floorDb, gamma;
        topDb   = -6.0;
        floorDb = -60.0;
        gamma   = 1.0;
        safeLin = linear.max(1e-9);
        db  = safeLin.ampdb.clip(floorDb, topDb);
        ui  = (db - floorDb) / (topDb - floorDb);
        ui.pow(gamma)
    };

    // Build LPDisplay with the HUD map; then wire canonical responders
    displayLayoutWindow = LPDisplayLayoutWindow.new(hudMapFunction);
    displayLayoutWindow.setHudMap(hudMapFunction);

    // Optional labels for sources
    displayLayoutWindow.setSourceA(\chainA);
    displayLayoutWindow.setSourceB(\chainB);

    // Install meter responders (expects /peakrmsA and /peakrmsB)
    displayLayoutWindow.installMeterResponders();

    // Optional console prints for levels while debugging
    displayLayoutWindow.setConsoleLevelsOn(true);

    // Open window and set initial active-chain visual
    displayLayoutWindow.open();
    displayLayoutWindow.setActiveChainVisual(\A);

    prefix = "LPDisplay";
    topWindow = findWindowByPrefix.(prefix);
    if(topWindow.isNil) {
        "Warning: could not locate LPDisplay window by prefix; falling back to last window".postln;
        topWindow = Window.allWindows.last;
    };

    "LPDisplay window opened.".postln;
};

// --- chain switch helpers (manual; MIDI deferred) ---
switchToChainA = {
    Ndef(\chainB).stop;
    Ndef(\chainA).play;
    if(displayLayoutWindow.notNil) { displayLayoutWindow.setActiveChainVisual(\A) };
    "[SWITCH] Active chain = A".postln;
};

switchToChainB = {
    Ndef(\chainA).stop;
    Ndef(\chainB).play;
    if(displayLayoutWindow.notNil) { displayLayoutWindow.setActiveChainVisual(\B) };
    "[SWITCH] Active chain = B".postln;
};

// --- bring-up sequence ---
setupServer.();
setupAudioGraphs.();
openDisplayWindow.();

// Export helpers for quick manual toggles in the post window
~switchToChainA = switchToChainA;
~switchToChainB = switchToChainB;

"Bring-up complete. Try ~switchToChainB.() then ~switchToChainA.() to toggle chains.".postln;

topWindow;  // -> a Window
)
