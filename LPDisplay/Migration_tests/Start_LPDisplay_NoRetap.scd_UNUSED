// Start_LPDisplay_NoRetap.scd
// v0.1.1
// MD 20251003-1642

/*
Purpose
- Open LPDisplayLayoutWindow; bring up LivePedalboardSystem headless;
- Enable inline SendPeakRMS taps (/peakrmsA, /peakrmsB) inside Ndef chains;
- Ensure audible source; bind display adapter for text panes; no retap scripts needed.
Style
- Single ( ) block; var-first; ~ tilde vars only; Server.default.bind for server ops;
  AppClock for GUI; no server.sync; returns -> a Window.
*/

(
var okWin, okSystem;

// 1) LPDisplay controller + window (meters listen to /peakrmsA/B)
~guiLP = LPDisplayLayoutWindow.new;
~win = ~guiLP.open;                         // -> a Window
// Keep the window's internal demo sources silent so meters reflect LPS chains only
~guiLP.setSourceA(\srcZ);
~guiLP.setSourceB(\srcZ);

// 2) LivePedalboardSystem up (headless UI)
~system = LivePedalboardSystem.new(nil);
~system.ensureServerReady;
~system.bringUpPedalboard;
~system.bringUpCommandSystem;
~system.installAdapterBridge;               // routes canonical paths ("/add/...", "/switch", ...)

// 3) Enable inline SendPeakRMS taps (sends /peakrmsA & /peakrmsB)
~system.enableAutoMeters(20);

// 4) Bind CommandManager -> LPDisplay text panes (optional but recommended)
~system.autoBindLPDisplayIfPresent;

// 5) Make sure something is audible; CURRENT plays (inactive chain silenced at source)
~system.ensureAudioOn;

// 6) Quick acceptance print
okWin = (~win.notNil);
okSystem = (~system.notNil) and: { ~system.commandManager.notNil };
[ \lpWindow, okWin, \systemUp, okSystem ].postln;

// Final expression keeps the window "-> a Window"
~win
)