// LPDisplay_AllInOne_BringUp.scd
// v0.9.8 — open the layout test window + export helpers for a guided tour
// MD 2025-10-01

/*
Purpose
- One-file bring-up for the LivePedalboardDisplay demo window:
  * Open a 6-pane GUI with A/B meters driven by SendPeakRMS.
  * Create a HUD mapper (dB headroom + gamma) and allow on/off toggling.
  * Provide safe, readable one-liners to swap sources and send pane text.
  * Keep to known-good wiring: Ndef(left) <<> Ndef(right); sinks read \in.ar(2).

Style / Conventions
- var-first declarations; descriptive names; tilde vars exported for convenience.
- No server.sync; GUI ops are deferred inside the window class.
- Single bring-up block that returns -> a Window.
- No SoundIn; the window defines internal demo sources/sinks (stereo).
- If the classes are missing, recompile after installing them at:
  .../PhD_projects/LivePedalboardSuite/LivePedalboardDisplay/Classes/
*/

(
var hud, inst, win;

// --- Create a HUD map (top/floor/gamma), then build the window instance
hud  = LPDisplayHudMap.new(-6, -60, 1.0);         // defaults: headroom -6 dB, floor -60 dB, gamma 1.0
inst = LPDisplayLayoutTestWindow.new(hud);        // pass nil here if you prefer raw 0..1 meters initially

// --- Open the window (the class ensures only one "Layout Test" window is active)
win = inst.open;                                  // -> a Window

// --- Export handles (tilde vars) so you can drive the demo interactively
~hud  = hud;          // current HUD map instance (may be replaced by ~hud_on)
~inst = inst;         // the layout test window controller (has setSourceA/B, setHudMap, sendPaneText, printHud)
~win  = win;          // the Window; optional use

// --- Demo helpers: all nil-safe through the class methods they call
~hud_on  = { |topDb = -6, floorDb = -60, gamma = 1.0|
    var newHud = LPDisplayHudMap.new(topDb, floorDb, gamma);
    ~hud = newHud;
    ~inst.setHudMap(newHud).printHud;
};

~hud_off = {
    ~inst.setHudMap(nil).printHud;
};

~hud_set = { |key, value|
    // Ensure we have a HUD instance, then tweak a single parameter (\top, \floor, \gamma)
    ~hud = ~hud ?? { LPDisplayHudMap.new(-6, -60, 1.0) };
    ~inst.setHudMap(~hud);  // ensure mapping is active while tweaking
    ~hud.set(key, value).print;  // prints settings
};

~hud_preview = { |rmsDb = -9|
    // Convenience to see the UI mapping for a specific RMS dB value
    ~hud = ~hud ?? { LPDisplayHudMap.new(-6, -60, 1.0) };
    ~hud.preview(rmsDb);
};

~setA = { |sym|  ~inst.setSourceA(sym) };         // e.g., ~setA.(\srcC)
~setB = { |sym|  ~inst.setSourceB(sym) };         // e.g., ~setB.(\srcA)

~text = { |paneKey, aString|
    // paneKey ∈: \left, \right, \system, \diag, \choices, \recv
    ~inst.sendPaneText(paneKey, aString);
};

~print_hud = {  ~inst.printHud  };

~close = {
    // Close the window and free OSCdefs & Ndefs inside the class
    ~inst.close;
};

// --- Friendly banner so the recipient knows what to try next:
"LivePedalboardDisplay — bring-up complete. See 'Quick Tour' below for optional steps.".postln;
"Tip: you can now call ~hud_off.(), ~hud_on.(), ~setA.(\\srcC), ~text.(\\diag, \"Hello\").".postln;

// Return the Window so SC shows '-> a Window'
win
)
