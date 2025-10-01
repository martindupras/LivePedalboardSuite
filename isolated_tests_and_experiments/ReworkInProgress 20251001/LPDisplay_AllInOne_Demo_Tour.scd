
// LPDisplay_AllInOne_Demo_Tour.scd
// v0.9.8 — single-file bring-up + guided quick tour (evaluate blocks top-to-bottom)
// MD 2025-10-01

/*
Overview
- This single .scd opens the LivePedalboardDisplay demo window and provides a guided "Quick Tour".
- The window shows A/B chains with meters (via SendPeakRMS), optional HUD mapping (dB headroom + gamma),
  and several text panes you can write to.

Prerequisites
- Ensure these classes are installed and you have recompiled the class library:
  .../PhD_projects/LivePedalboardSuite/LivePedalboardDisplay/Classes/
    • LPDisplayHudMap.sc
    • LPDisplaySigChain.sc
    • LPDisplayLayoutTestWindow.sc
  SuperCollider menu: Language → Recompile Class Library

How to use this file
1) Evaluate the first block (Bring-Up). You should see '-> a Window'.
2) Then evaluate the Quick Tour chunks (00..06) as needed, one line at a time or a few at a time.
3) To close and clean up, evaluate the Close chunk (06) at the end.

Style / Coding rules
- var-first declarations; descriptive names; GUI updates are deferred in the classes.
- JITLib wiring strictly: Ndef(left) <<> Ndef(right). Sinks read \in.ar(2).
- Generated demo sources only (no SoundIn).
*/

(
// --- Bring-Up: create HUD, create instance, open the window, export helpers ---
var hud, inst, win;

hud  = LPDisplayHudMap.new(-6, -60, 1.0);           // defaults: top=-6 dB, floor=-60 dB, gamma=1.0
inst = LPDisplayLayoutTestWindow.new(hud);          // pass nil if you prefer raw meters initially
win  = inst.open;                                   // -> a Window (ensures only one "Layout Test")

// Export handles for interactive use during the tour
~hud  = hud;                                        // current HUD instance (may be replaced)
~inst = inst;                                       // the controller (has setSourceA/B, setHudMap, sendPaneText, printHud)
~win  = win;                                        // the Window

// Helper one-liners used by the tour
~hud_on  = { |topDb = -6, floorDb = -60, gamma = 1.0|
    var newHud = LPDisplayHudMap.new(topDb, floorDb, gamma);
    ~hud = newHud;
    ~inst.setHudMap(newHud).printHud;               // console prints HUD params
};

~hud_off = {
    ~inst.setHudMap(nil).printHud;                  // console: "HUD mapping: none (raw 0..1)"
};

~hud_set = { |key, value|
    ~hud = ~hud ?? { LPDisplayHudMap.new(-6, -60, 1.0) };
    ~inst.setHudMap(~hud);
    ~hud.set(key, value).print;                     // tweak \top/\floor/\gamma; prints settings
};

~hud_preview = { |rmsDb = -9|
    ~hud = ~hud ?? { LPDisplayHudMap.new(-6, -60, 1.0) };
    ~hud.preview(rmsDb);                             // prints UI fraction for given dB RMS
};

~setA = { |sym|  ~inst.setSourceA(sym) };           // e.g., ~setA.(\srcC)
~setB = { |sym|  ~inst.setSourceB(sym) };           // e.g., ~setB.(\srcA)

~text = { |paneKey, aString|                        // pane keys: \left, \right, \system, \diag, \choices, \recv
    ~inst.sendPaneText(paneKey, aString);
};

~print_hud = {  ~inst.printHud  };

~close = {
    ~inst.close;                                     // frees OSCdefs; stops sink Ndefs; closes window
};

"LivePedalboardDisplay — bring-up complete. See Quick Tour blocks below.".postln;
"Tip: try ~hud_off.(), ~hud_on.(-9, -60, 1.0), ~setA.(\\srcC), ~text.(\\diag, \"Hello\").".postln;

win                                                // return -> a Window
)


// =============================
// Quick Tour 00 — Sanity checks
// =============================

// LPDisplay_Tour_00_Sanity
// v1.0 — MD 2025-10-01
//
// Purpose
// - Confirm bring-up ran and helpers exist before running the tour.
// Style
// - Each line prints a boolean; 'true' means you're good to proceed.

(~inst.notNil).postln;                               // expected: true
~inst.respondsTo(\setHudMap).postln;                 // expected: true
(~text.notNil).postln;                               // expected: true
(~hud_on.notNil and: { ~hud_off.notNil }).postln;    // expected: true


// ==========================================
// Quick Tour 01 — Verify window + status text
// ==========================================

// LPDisplay_Tour_01_VerifyAndStatus
// v1.0 — MD 2025-10-01
//
// Purpose
// - Confirm the window is open and panes update.
// Style
// - Evaluate lines one by one; text should appear immediately.

~text.(\diag,   "Ready @ " ++ Date.getDate.stamp);  // diag pane prints timestamp
~text.(\system, "A/B chains running. HUD is ON by default."); // system pane status


// =======================================
// Quick Tour 02 — Swap tail sources (A/B)
// =======================================

// LPDisplay_Tour_02_SwapTailSources
// v1.0 — MD 2025-10-01
//
// Purpose
// - Swap each chain's tail source; you will hear/see changes.
// Style
// - After swap, the window auto-updates the top labels to show the new chain strings.

~setA.(\srcC);                                       // A tail -> \srcC (LFSaw/tanh) ; left meter responds
~setB.(\srcA);                                       // B tail -> \srcA (PinkNoise)  ; right meter responds
~text.(\diag, "Swapped: A->\\srcC, B->\\srcA");     // diag note confirming the change


// ==============================================
// Quick Tour 03 — Toggle HUD mapping & preview UI
// ==============================================

// LPDisplay_Tour_03_ToggleHUD
// v1.0 — MD 2025-10-01
//
// Purpose
// - Show raw meters (no mapping), then enable HUD with new top/floor/gamma.
// - Preview mapping for a specific RMS dB value.
// Style
// - Use helpers created at bring-up.

~hud_off.();                                         // raw linear RMS on meters ; console prints mapping=none
~hud_on.(-9, -60, 1.0);                              // enable mapping top=-9 ; console prints params
~hud_set.(\gamma, 1.2);                              // add curvature ; console prints updated params
~hud_preview.(-9);                                   // prints UI fraction for -9 dB RMS ; e.g., 0.83
~print_hud.();                                       // print current HUD parameters


// ============================================
// Quick Tour 04 — Populate the lower text panes
// ============================================

// LPDisplay_Tour_04_Panes_Content
// v1.0 — MD 2025-10-01
//
// Purpose
// - Simulate a fuller display by writing to \choices and \recv.
// Style
// - Multiline strings using \n.

~text.(\choices,
"Choices:\n  1) Swap A/B\n  2) Toggle HUD\n  3) Send message\n  4) Close");            // choices pane shows 4 options

~text.(\recv,
"Receiving:\n  /peakrmsA and /peakrmsB @ 20 Hz\n  Console prints ~1 Hz (decimated)"); // recv pane shows OSC info


// =====================================
// Quick Tour 05 — Lightweight smoke tests
// =====================================

// LPDisplay_Tour_05_SmokeTests
// v1.0 — MD 2025-10-01
//
// Purpose
// - Quick PASS/FAIL checks in the Post window.
// Style
// - Run while the main demo window is open. Avoid LPDisplayLayoutTestWindow.test here.

LPDisplayHudMap.test;                                 // expected: prints cases + "LPDisplayHudMap.test: PASS"
LPDisplaySigChain.test;                               // expected: brief run + "LPDisplaySigChain.test: PASS"


// ================================
// Quick Tour 06 — Close and cleanup
// ================================

// LPDisplay_Tour_06_Close
// v1.0 — MD 2025-10-01
//
// Purpose
// - Cleanly close the window and free responders.
// Style
// - Re-run the Bring-Up block to open again.

~close.();                                            // expected: window closes; OSCdefs freed; sinks stopped


// ======================================================
// Optional: One-button smoke runner (evaluate as a block)
// ======================================================

// LPDisplay_Tour_07_OneButtonSmoke
// v1.0 — MD 2025-10-01
//
// Purpose
// - Minimal automated walk-through: flip sources, post a diag line, print HUD, then stop.
// Style
// - Safe timings via AppClock; does not assume SoundIn.

(
var step1, step2;
step1 = {
    ~setA.(\srcC); ~setB.(\srcA);                    // swap tails
    ~text.(\diag, "Smoke: swapped A/B @ " ++ Date.getDate.stamp);
};
step2 = {
    ~print_hud.();                                    // print active HUD state
    ~text.(\system, "Smoke: HUD printed; closing in 1s");
    AppClock.sched(1.0, { ~close.(); nil });          // close after 1s
};
AppClock.sched(0.5, { step1.(); AppClock.sched(1.0, { step2.(); nil }); nil });
)
