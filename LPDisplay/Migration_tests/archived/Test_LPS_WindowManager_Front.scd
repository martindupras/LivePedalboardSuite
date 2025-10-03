// Test_LPS_WindowManager_Front.scd
// v0.1.0
// MD 20251003-1125

/* Purpose/Style:
- Brings the single policy window to front (no recreation).
- If missing, returns nil (prints info); otherwise returns '-> a Window'.
*/

(
var windowPrefix, win;

("Running: Test_LPS_WindowManager_Front.scd").postln;

windowPrefix = "MagicDisplayGUI";

win = ~lps_frontByPrefix.(windowPrefix);

if(win.isNil) {
    ("No window found with prefix '" ++ windowPrefix ++ "'").postln;
} {
    ("Fronted window: " ++ win.name.asString).postln;
};

// Return -> a Window (or nil if none existed)
win
)
