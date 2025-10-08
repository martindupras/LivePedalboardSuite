// PedalboardStarter.scd
// v0.1.5
// MD 20251008-1328

/*
Purpose
- Minimal, thin bring-up using yesterday's proven chains and metering.
- Fixes: use LPDisplayHudMap (not a bare Function), clear old Ndefs, create audio only after server boot.
- A = Active (audible), B = Next (stopped). Top panes titled/highlighted accordingly.

Style / Guards
- One single block; var-first; lowercase identifiers; no server.sync; no non-local returns.
- GUI on AppClock only; returns '-> a Window'.
*/

(
var displayLayoutWindow, topWindow, meterHudMap;
var openDisplayWindow, setTopPaneTitlesAndStyles, bringUpAudioAfterBoot;
var defineGeneratorsMetersSinks, connectDefaultChains, clearOldProxies;
var findWindowByPrefix, closeExistingLpDisplayWindows;

"==================== PedalboardStarter (v0.1.5) ====================".postln;

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

// ---------- LPDisplay bring-up (safe before server boot) ----------
openDisplayWindow = {
    var prefix;
    closeExistingLpDisplayWindows.();

    // Use LPDisplayHudMap (required; LPDisplay calls .mapLinToUi under the hood)
    meterHudMap = LPDisplayHudMap.new(-6, -60, 1.0);
    displayLayoutWindow = LPDisplayLayoutWindow.new(meterHudMap);
    displayLayoutWindow.setHudMap(meterHudMap);

    displayLayoutWindow.installMeterResponders();  // listens on /peakrmsA and /peakrmsB
    displayLayoutWindow.setConsoleLevelsOn(false);
    displayLayoutWindow.open();

    // Titles + highlight for bring-up: A active, B next (visuals first; audio follows after boot)
    setTopPaneTitlesAndStyles.(\A);

    prefix = "LPDisplay";
    topWindow = findWindowByPrefix.(prefix);
    if(topWindow.isNil) { topWindow = Window.allWindows.last };

    "LPDisplay window opened; waiting for server to boot for audio...".postln;
};

// ---------- helper: set top-pane titles and highlight ----------
setTopPaneTitlesAndStyles = { |activeChainSym|  // \A or \B
    // Assuming \left / \right for title/style
    if(activeChainSym == \A) {
        displayLayoutWindow.setTopPaneTitle(\left,  "Chain A (Active)");
        displayLayoutWindow.setTopPaneTitle(\right, "Chain B (Next)");
        displayLayoutWindow.setTopPaneStyle(\left,  true);
        displayLayoutWindow.setTopPaneStyle(\right, false);
        displayLayoutWindow.setActiveChainVisual(\A);
    }{
        displayLayoutWindow.setTopPaneTitle(\left,  "Chain A (Next)");
        displayLayoutWindow.setTopPaneTitle(\right, "Chain B (Active)");
        displayLayoutWindow.setTopPaneStyle(\left,  false);
        displayLayoutWindow.setTopPaneStyle(\right, true);
        displayLayoutWindow.setActiveChainVisual(\B);
    };
};

// ---------- cleanup: clear any old proxies to avoid Group-not-found ----------
clearOldProxies = {
    [\sinkA, \sinkB, \meterA, \meterB, \testmelodyA, \testmelodyB, \silence,
     \srcPink, \srcSquare88, \srcPulseTrain134, \srcPulsedNoise7, \srcBleeps].do { |sym|
        if(Ndef.all.keys.includes(sym)) { Ndef(sym).clear };
    };
    "Cleared any old proxies for A/B bring-up.".postln;
};

// ---------- your generators, meters, sinks (from your working code) ----------
defineGeneratorsMetersSinks = {
    // Test melodies (stereo)
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

    // Meters: use \in.ar(0!2) + SendPeakRMS to canonical OSC paths
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

    // Sinks: pass-through of \in.ar(0!2); audible by playing the sink
    Ndef(\sinkA, { var inSig = \in.ar(0!2); inSig });
    Ndef(\sinkB, { var inSig = \in.ar(0!2); inSig });

    "Generators/meters/sinks defined.".postln;
};

// ---------- connect chains and set audible state (A play, B stop) ----------
connectDefaultChains = {
    Ndef(\sinkA) <<> Ndef(\meterA) <<> Ndef(\testmelodyA);
    Ndef(\sinkB) <<> Ndef(\meterB) <<> Ndef(\testmelodyB);

    // Audible state (play/stop after server boot)
    Ndef(\sinkA).play;
    Ndef(\sinkB).stop;

    "Chains connected: sinkA<<meterA<<testmelodyA (PLAY), sinkB<<meterB<<testmelodyB (STOP).".postln;
};

// ---------- bring up audio only after server is ready ----------
bringUpAudioAfterBoot = {
    s.waitForBoot({
        Server.default.bind({
            "Server booted; initializing tree…".postln;
            s.initTree;
            s.defaultGroup.freeAll;

            clearOldProxies.();
            defineGeneratorsMetersSinks.();
            connectDefaultChains.();

            // Ensure visuals match audible
            setTopPaneTitlesAndStyles.(\A);

            "Audio bring-up completed.".postln;
        });
    });
};

// ---------- sequence ----------
openDisplayWindow.();      // open GUI now so we still return -> a Window
bringUpAudioAfterBoot.();  // defer audio graphs until server is ready

"Bring-up running. Use ~switchToChainB.() / ~switchToChainA.() to toggle once audio is up.".postln;

// Manual toggle helpers (work after audio is up)
~switchToChainA = {
    Ndef(\sinkB).stop; Ndef(\sinkA).play;
    setTopPaneTitlesAndStyles.(\A);
    "[SWITCH] Active chain = A".postln;
};

~switchToChainB = {
    Ndef(\sinkA).stop; Ndef(\sinkB).play;
    setTopPaneTitlesAndStyles.(\B);
    "[SWITCH] Active chain = B".postln;
};

topWindow;  // -> a Window (immediate)
)