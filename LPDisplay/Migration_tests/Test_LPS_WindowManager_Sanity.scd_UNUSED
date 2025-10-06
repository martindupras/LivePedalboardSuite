// Test_LPS_WindowManager_Sanity.scd
// v0.1.1
// MD 20251003-1138

/* Purpose/Style:
- Confirm helpers are installed after running the *_Install.scd script.
*/

(
var hasBringUp, hasFind;

("Running: Test_LPS_WindowManager_Sanity.scd").postln;

hasBringUp = (~lps_bringUpSingleWindow.notNil) and: { ~lps_bringUpSingleWindow.isKindOf(Function) };
hasFind = (~lps_findWindowsByPrefix.notNil) and: { ~lps_findWindowsByPrefix.isKindOf(Function) };

("hasBringUp: " ++ hasBringUp.asString).postln;
("hasFind:    " ++ hasFind.asString).postln;
)