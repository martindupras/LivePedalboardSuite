// MagicDisplayGUI_HUD_AddLabels_v0.3.7.scd
// v0.3.7
// MD timestamp: 2025-09-25

/* Purpose
   - Add simple HUD labels inside the existing MagicDisplayGUI A/B window.
   - Top-left anchored, no FlowLayout; read-only labels for the demo.

   Style
   - var-first in every block; no non-local returns (^).
*/

(
var ok, win, content, hudTitle, hudA, hudB;

ok = true;

win = ~mdGui_window;

if (win.isNil) {
    "No MagicDisplayGUI window found. Open MagicDisplayGUI_New_Window_AB_v0.3.7.scd first.".postln;
} {
    content = win.view;

    // Title HUD
    hudTitle = StaticText(content, Rect(16, 0, 400, 12));
    hudTitle.string = "HUD: A=replyID 2001 | B=replyID 2002 | fallback=test 1001";
    hudTitle.stringColor = Color.gray(0.8);
    hudTitle.background = Color.clear;
    hudTitle.align = \left;

    // Chain labels (editable here if you want different names)
    hudA = StaticText(content, Rect(16, 24, 200, 12));
    hudA.string = "A: Ndef(\\chainA)";
    hudA.stringColor = Color.gray(0.8);
    hudA.background = Color.clear;
    hudA.align = \left;

    hudB = StaticText(content, Rect(292, 24, 200, 12));
    hudB.string = "B: Ndef(\\chainB)";
    hudB.stringColor = Color.gray(0.8);
    hudB.background = Color.clear;
    hudB.align = \left;
};

ok;
)
