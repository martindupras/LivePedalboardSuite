// RunBook.scd
// MD
// 20251002-1157

/*
--- > RUN BLOCK BY BLOCK! <--
*/

//////////////////////////////
// 0) Clean up (safe preflight)

(
// Close LPDisplay / MagicDisplay windows
Window.allWindows
 .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI")
        or: { w.tryPerform(\name) == "Layout Test" } })
 .do(_.close);

// Free OSCdefs used by the LPDisplay demo (if present)
[ \rmsA_toGUI, \rmsB_toGUI, \rmsA_console, \rmsB_console ].do { |k|
    var d = OSCdef(k); if(d.notNil) { d.free };
};

// Stop the LPDisplay demo Ndefs if they exist
[ \srcA, \srcB, \srcC, \srcZ, \outA, \outB ].do { |sym|
    var nd = Ndef(sym); if(nd.notNil) { nd.stop };
};
"Cleanup done.".postln;
)


//////////////////////////////
// 1) Open LPDisplay window (silence its internal demo sources)
(
// Controller (instance with setSourceA/B) and GUI window
~inst = LPDisplayLayoutTestWindow.new(nil);  // pass a HUD object if you prefer; nil = raw meters
~win  = ~inst.open;                          // -> a Window titled "Layout Test"

// Silence the LPDisplay demo sources so the meters don't show its noise/tone
~inst.setSourceA(\srcZ);
~inst.setSourceB(\srcZ);

// If you added the console gate previously:
try { ~inst.setConsoleLevelsOn(false) } { };  // optional: keep console quiet

// Ready check
[ ~inst.notNil, ~win.notNil, ~win.class ].postln;
)

//////////////////////////////
// 2) Bring up LivePedalboardSystem (headless UI)
(
~system = LivePedalboardSystem.new(nil);
~system.ensureServerReady;
~system.bringUpPedalboard;      // MagicPedalboardNew
~system.bringUpCommandSystem;   // CommandManager + MIDI
~system.installAdapterBridge;   // routes '/add/delay', '/switch', etc. to MPB
"OK: LPS up (headless UI).".postln;

// Sanity
[ ~system.notNil, ~system.pedalboard.notNil, ~system.commandManager.notNil ].postln;
)

//////////////////////////////
// 3) Confirm core objects and callback exist
(
~cm = ~system.commandManager;
~mm = ~cm.midiManager;
[ ~system.notNil, ~cm.notNil, ~mm.notNil, (~cm.queueExportCallback.notNil) ].postln;
)


//////////////////////////////
//4) Load the emulator helpers (block [1] in the emulator file)

/*
Open Demo-simulated/Sim_MIDIInput_Emulator_For_TreeNav.scd and evaluate the parenthesized block under [1] Emulation helpers.
That block defines: ~fc, ~toProg, ~toQueue, ~toSend, ~gm, ~nav, ~showNav, etc.
*/
//verify helps exist:
[ ~toProg.isKindOf(Function), ~nav.isKindOf(Function), ~toQueue.isKindOf(Function), ~toSend.isKindOf(Function) ].postln;
// Expect: [ true, true, true, true ]


//////////////////////////////
//5) Scenario A — Add Delay (navigate → queue → send)
(
~toProg.();           // enter navigation mode
~nav.(6, 1);          // "audio"
~nav.(5, 5);          // "timebased"
~nav.(4, 3);          // "delay"
~showNav.();          // optional: prints long/canonical path
~toQueue.();          // queue canonical (e.g. "/add/delay")
~toSend.();           // send via adapter -> MagicPedalboardNew
)

//////////////////////////////
//6) Scenario B — Switch chains
(
~toProg.();
~nav.(6, 5);          // "switch"
~showNav.();
~toQueue.();
~toSend.();
)


//////////////////////////////
//

//////////////////////////////
//

//////////////////////////////
//

//////////////////////////////
//