// Start_LPS_with_LPDisplay_Muted.scd
// v0.2.0
// MD 20251006-1720

/*
Purpose
- Deterministic bring-up for LPDisplay + MagicPedalboard + CommandManager.
- Wires chainA->testmelodyA and chainB->testmelodyB, installs in-graph meters,
  and defaults to MUTE ON (post-meter) so meters move while silent.
Style
- Single () block; var-first; Server.default.bind; AppClock for GUI; no server.sync.
- Returns -> a Window; defines ~muteAudio / ~unmuteAudio for quick control.
*/

(
var win, lps;

// 0) Close any prior windows
Window.allWindows
.select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") or: { w.tryPerform(\name) == "Layout Test" } })
.do(_.close);

// 1) System
lps = LivePedalboardSystem.new(nil);
lps.ensureServerReady;
win = lps.bringUpLPDisplay;              // -> a Window
lps.bringUpPedalboard;
lps.bringUpCommandSystem;
lps.installAdapterBridge;

// 2) Ensure chain sink proxies exist (stereo), and taps -> /peakrmsA/B
lps.enableAutoMeters(24, 0.35);

// 3) Ensure our stereo test sources exist (from Define_TestMelodies_A_B.scd)
Server.default.bind({
    if (Ndef(\testmelodyA).source.isNil) {
        Ndef(\testmelodyA, { Silent.ar(2) }); Ndef(\testmelodyA).ar(2);
    };
    if (Ndef(\testmelodyB).source.isNil) {
        Ndef(\testmelodyB, { Silent.ar(2) }); Ndef(\testmelodyB).ar(2);
    };
});

// 4) Wire: chainA <- testmelodyA, chainB <- testmelodyB
//    (Do this *after* pedals/bridge so our wiring "wins" deterministically)
Server.default.bind({
    // The <<> operator: left receives right at \in
    Ndef(\chainA) <<> Ndef(\testmelodyA);
    Ndef(\chainB) <<> Ndef(\testmelodyB);
});

// 5) Assert stereo & start CURRENT only (Option A style).
//    We start A, stop B; exclusive audio can be enforced via mute toggles below.
Server.default.bind({
    Ndef(\chainA).ar(2); Ndef(\chainB).ar(2);
    if (Ndef(\chainA).isPlaying.not) { Ndef(\chainA).play(numChannels: 2) };
    if (Ndef(\chainB).isPlaying)     { Ndef(\chainB).stop };
});

// 6) Default: MUTE ON (post-meter) so it’s quiet but meters move
Server.default.bind({
    Ndef(\chainA).filter(\audMute, { |in| in.isArray.if({ in*0 }, { [in, in]*0 }) });
    Ndef(\chainB).filter(\audMute, { |in| in.isArray.if({ in*0 }, { [in, in]*0 }) });
});

// 7) Show labels & ACTIVE in LPDisplay
lps.refreshDisplay;

// 8) Define handy toggles for you to call later
~muteAudio = {
    Server.default.bind({
        Ndef(\chainA).filter(\audMute, { |in| in.isArray.if({ in*0 }, { [in, in]*0 }) });
        Ndef(\chainB).filter(\audMute, { |in| in.isArray.if({ in*0 }, { [in, in]*0 }) });
    });
    "[Audio] MUTE ON (post-meter)".postln;
};

~unmuteAudio = {
    Server.default.bind({
        Ndef(\chainA).clear(\audMute);
        Ndef(\chainB).clear(\audMute);
    });
    "[Audio] MUTE OFF".postln;
};

// 9) Also define a quick manual A/B exclusivity switch (no CommandTree dependency)
~manualSwitchAB = {
    Server.default.bind({
        if (Ndef(\chainA).isPlaying) {
            Ndef(\chainA).stop; Ndef(\chainB).play(numChannels: 2);
        } {
            Ndef(\chainB).stop; Ndef(\chainA).play(numChannels: 2);
        };
    });
    // nudge UI ACTIVE highlight
    lps.statusDisplay.tryPerform(\setActiveChainVisual,
        Ndef(\chainA).isPlaying.if({ \A }, { \B })
    );
    "[Manual] switched ACTIVE to ".post; (Ndef(\chainA).isPlaying.if({ "A" }, { "B" })).postln;
};

// 10) Return window
win
)