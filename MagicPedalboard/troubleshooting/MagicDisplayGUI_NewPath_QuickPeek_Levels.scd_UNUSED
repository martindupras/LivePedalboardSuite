// MagicDisplayGUI_NewPath_QuickPeek_Levels.scd
// v0.1.0
// MD timestamp: 2025-09-25

/* Purpose
   - Print ~levels a few times to verify updates.
   - No top-level 'var'; local vars are inside the Routine function.

   Style
   - var-first inside the Routine; no non-local returns (^).
*/

~md_levelsPeek = Routine({
    var i;
    i = 0;
    12.do {
        ("~levels now: " ++ ~levels.asString).postln;
        0.25.wait;
    };
}).play(AppClock);
