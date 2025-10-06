// Start_LPDisplay_Minimal_NoEnsure.scd
// v0.1.0
// MD 20251006-1350

/*
Purpose
- Bring up LPDisplay + MagicPedalboard + CommandManager without relying on ensureServerReady.
- Returns -> a Window; meters use SendPeakRMS taps inside Ndefs.
Style
- Single () block; var-first; Server.default.bind; AppClock for GUI; no server.sync.
*/

(
var win, controller, adapter, lps;

// 0) Ensure server clean enough for bring-up
if(s.serverRunning.not) {
    s.boot;
    s.waitForBoot({ s.initTree; s.defaultGroup.freeAll; });
} {
    // Optional: minimal clean when already running
    Server.default.bind({ s.defaultGroup.freeAll; });
};

// 1) Open LPDisplay window (controller + view)
controller = LPDisplayLayoutWindow.new;
win = controller.open;                 // -> a Window
controller.setHudMap(LPDisplayHudMap.new(-6, -60, 1.0));
controller.setConsoleLevelsOn(false);

// 2) Build system (skip bringUpAll to avoid ensureServerReady)
lps = LivePedalboardSystem.new(nil);

// Attach adapter so CommandManager.display calls show in LPDisplay panes
adapter = LPDisplayAdapter.new(controller);
lps.statusDisplay_(adapter);           // uses the generated setter for <>statusDisplay

// 3) Pedalboard + command system + bridge + auto-meters
lps.bringUpPedalboard;
lps.bringUpCommandSystem;
lps.installAdapterBridge;
lps.enableAutoMeters(24, 0.35);        // taps SendPeakRMS inside Ndef(\chainA/\chainB)

// 4) Make some generated audio and play current (no SoundIn)
Server.default.bind({
    if(Ndef(\testmelody).source.isNil) {
        Ndef(\testmelody, {
            var trig = Impulse.kr(3.2);
            var seq = Dseq([220,277.18,329.63,392,329.63,277.18,246.94], inf);
            var f = Demand.kr(trig, 0, seq);
            var env = Decay2.kr(trig, 0.01, 0.35);
            Pan2.ar(SinOsc.ar(f) * env * 0.25, 0.0)
        });
    };
    Ndef(\testmelody).ar(2);
    Ndef(\chainA).ar(2);
    Ndef(\chainB).ar(2);
});

if(lps.pedalboard.respondsTo(\setSourceCurrent)) { lps.pedalboard.setSourceCurrent(\testmelody) };
if(lps.pedalboard.respondsTo(\playCurrent))     { lps.pedalboard.playCurrent };

// 5) Front the window; return -> a Window
AppClock.sched(0.0, { win.front; nil });
win
)