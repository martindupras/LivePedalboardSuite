// LPDisplay_CompatExports.scd
// v0.9.2 - shims for old tilde variables + bring-up
// MD 20251001

(
var hud, win, inst;

// Create a HUD map (or set to nil to keep raw 0..1 meters)
hud = LPDisplayHudMap.new(-6, -60, 1.0);

// Open the window (-> a Window)
win = LPDisplayLayoutWindow.new(hud).open; // the window
win = inst.open; // the controller for the window

// Export legacy one-liners:
~setSourceA = { |sym| inst.setSourceA(sym) };
~setSourceB = { |sym| inst.setSourceB(sym) };

// Pane text helper (keys: \left, \right, \system, \diag, \choices, \recv)
~lt_send = { |paneKey, aString| win.sendPaneText(paneKey, aString) };

// HUD helpers to mirror your previous patch commands:
~hud_set     = { |key, value| hud.set(key, value) };
~hud_preview = { |db| hud.preview(db) };
~hud_print   = { hud.print };

// Quick ping:
~hud_print.();
)