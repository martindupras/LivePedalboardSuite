// PedalboardStarter.scd
// v0.1.3
// MD 20251008-1238

/*
Purpose
- Minimal bring-up using yesterday's working test generators and chain wiring.
- A/B chains via Ndefs with your <<> operator; meters send /peakrmsA and /peakrmsB.
- LPDisplayLayoutWindow opens with top-pane titles:
  Left:  "Chain A (Active)"   Right: "Chain B (Next)"  (reflect state)
- Manual helpers switch A/B (MIDI deferred).

Style / Guards
- One single block; var-first; lowercase identifiers; no server.sync; no non-local returns.
- GUI on AppClock only; script returns '-> a Window'.
- Inside meter/sink graphs, use \in.ar(0!2) (stereo zeros) — NOT \in.ar(2).  // from your notes
*/

(
var displayLayoutWindow, topWindow, hudMapFunction;
var setupServer, defineGeneratorsMetersSinks, connectDefaultChains, openDisplayWindow, setTopPaneTitlesAndStyles;
var switchToChainA, switchToChainB, findWindowByPrefix, closeExistingLpDisplayWindows;

"==================== PedalboardStarter (v0.1.2) ====================".postln;

// ---------- server boot to known state ----------
setupServer = {
    s.waitForBoot({
        Server.default.bind({
            "Audio outputs: %".format(s.options.numOutputBusChannels).postln;
            s.initTree;
            s.defaultGroup.freeAll;
        });
    });
};

// ---------- enforce single LPDisplay window ----------
closeExistingLpDisplayWindows = {
    Window.allWindows.do({ |w|
        var name = w.name.asString;
        if(name.beginsWith("LPDisplay")) { w.close };
    });
};

// ---------- window lookup so we can return -> a Window ----------
findWindowByPrefix = { |prefixStr|
    Window.allWindows.detect({ |w| w.name.asString.beginsWith(prefixStr.asString) })
    ?? { Window.allWindows.last };
};

// ---------- your generators, meters, sinks (as in yesterday's file) ----------
defineGeneratorsMetersSinks = {
    // --- Generators: test melodies (stereo) ---
    Ndef(\testmelodyA, {
        var t = Impulse.kr(2.2);
        var e = Decay2.kr(t, 0.01, 0.30);
        var f = Demand.kr(t, 0, Dseq([220, 277.18, 329.63, 392], inf));
        (SinOsc.ar(f) * e * 0.22)!2
    });

    Ndef(\testmelodyB, {
        var t = Impulse.kr(3.1);
        var e = Decay2.kr(t, 0.02, 0.18);
        var f = Demand.kr(t, 0, Dseq([392, 329.63, 246.94, 220, 246.94], inf));
        (Pulse.ar(f, 0.35) * e * 0.20)!2
    });

    // --- Meters: use your SendPeakRMS + in.ar(0!2) pattern ---
    Ndef(\meterA, {
        var inSig = \in.ar(0!2);
        SendPeakRMS.kr(inSig, 20, 3, '/peakrmsA', 9876);
        inSig
    });

    Ndef(\meterB, {
        var inSig = \in.ar(0!2);
        SendPeakRMS.kr(inSig, 20, 3, '/peakrmsB', 9877);
        inSig
    });

    // --- Sinks: pass-through of in.ar(0!2) (audible via .play on the sink) ---
    Ndef(\sinkA, { var inSig = \in.ar(0!2); inSig });
    Ndef(\sinkB, { var inSig = \in.ar(0!2); inSig });

    "Generators/meters/sinks defined (testmelodyA/B, meterA/B, sinkA/B).".postln;
};

// ---------- connect default chains (A audible, B stopped) ----------
connectDefaultChains = {
    // Use your preferred operator: Ndef(left) <<> Ndef(right)
    Ndef(\sinkA) <<> Ndef(\meterA) <<> Ndef(\testmelodyA);
    Ndef(\sinkB) <<> Ndef(\meterB) <<> Ndef(\testmelodyB);

    // Audible state: A=true, B=false (play/stop on sinks)
    Ndef(\sinkA).play;
    Ndef(\sinkB).stop;

    "Chains connected: sinkA<<meterA<<testmelodyA (PLAY), sinkB<<meterB<<testmelodyB (STOP).".postln;
};

// ---------- LPDisplay bring-up and top-pane titles/styles ----------
openDisplayWindow = {
    var prefix;
    closeExistingLpDisplayWindows.();

    // Headroom map: top -6 dB, floor -60 dB, gamma 1.0
    hudMapFunction = { |linear|
        var safeLin = linear.max(1e-9);
        var db = safeLin.ampdb.clip(-60.0, -6.0);
        var ui = (db + 60.0) / (54.0);  // (-60..-6) -> (0..1)
        ui.pow(1.0)
    };

    // Build LPDisplay and arm meter responders
    displayLayoutWindow = LPDisplayLayoutWindow.new(hudMapFunction);
    displayLayoutWindow.setHudMap(hudMapFunction);

    // If you want labels, you can enable these; commented to keep minimal
    // displayLayoutWindow.setSourceA(\chainA);
    // displayLayoutWindow.setSourceB(\chainB);

    displayLayoutWindow.installMeterResponders();
    displayLayoutWindow.setConsoleLevelsOn(false);  // quieter console
    displayLayoutWindow.open();

    // Set titles + highlight for bring-up (A active, B next)
    setTopPaneTitlesAndStyles.(\A);

    prefix = "LPDisplay";
    topWindow = findWindowByPrefix.(prefix);
    if(topWindow.isNil) { topWindow = Window.allWindows.last };

    "LPDisplay window opened and armed for /peakrmsA/B.".postln;
};

// ---------- helper: set top-pane titles and highlight ----------
setTopPaneTitlesAndStyles = { |activeChainSym|  // \A or \B
    // Assuming API uses \left / \right for top panes:
    if(activeChainSym == \A) {
        displayLayoutWindow.setTopPaneTitle(\left, "Chain A (Active)");
        displayLayoutWindow.setTopPaneTitle(\right, "Chain B (Next)");
        displayLayoutWindow.setTopPaneStyle(\left, true);
        displayLayoutWindow.setTopPaneStyle(\right, false);
        displayLayoutWindow.setActiveChainVisual(\A);
    }{
        displayLayoutWindow.setTopPaneTitle(\left, "Chain A (Next)");
        displayLayoutWindow.setTopPaneTitle(\right, "Chain B (Active)");
        displayLayoutWindow.setTopPaneStyle(\left, false);
        displayLayoutWindow.setTopPaneStyle(\right, true);
        displayLayoutWindow.setActiveChainVisual(\B);
    };
};

// ---------- manual chain switch helpers (MIDI deferred) ----------
switchToChainA = {
    Ndef(\sinkB).stop;
    Ndef(\sinkA).play;
    setTopPaneTitlesAndStyles.(\A);
    "[SWITCH] Active chain = A".postln;
};

switchToChainB = {
    Ndef(\sinkA).stop;
    Ndef(\sinkB).play;
    setTopPaneTitlesAndStyles.(\B);
    "[SWITCH] Active chain = B".postln;
};

// ---------- bring-up sequence ----------
setupServer.();
defineGeneratorsMetersSinks.();
connectDefaultChains.();
openDisplayWindow.();

// export helpers for quick manual toggles
~switchToChainA = switchToChainA;
~switchToChainB = switchToChainB;

"Bring-up complete. Use ~switchToChainB.() / ~switchToChainA.() to toggle.".postln;

topWindow;  // -> a Window
)