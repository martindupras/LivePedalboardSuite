// MagicDisplayGUI_OSC_TraceAndReport_v0.3.11.scd
// v0.3.11
// MD timestamp: 2025-09-25

/* Purpose
   - Trace /md/levels briefly and then print active replyIDs with current values.
   - Announces itself in the console.

   Style
   - var-first; no non-local returns (^).
*/

(
var postStatus;

"=== RUN MagicDisplayGUI_OSC_TraceAndReport_v0.3.11 ===".postln;

postStatus = {
    var keys, msg;
    keys = if (~md_levelsById.notNil) { ~md_levelsById.keys.asArray.sort } { [] };
    msg = "Active replyIDs: " ++ keys.asString;
    msg.postln;
    if (~md_levelsById.notNil) {
        if (~md_levelsById[2001].notNil) { ("A (2001): " ++ ~md_levelsById[2001].asString).postln; };
        if (~md_levelsById[2002].notNil) { ("B (2002): " ++ ~md_levelsById[2002].asString).postln; };
        if (~md_levelsById[1001].notNil) { ("Test (1001): " ++ ~md_levelsById[1001].asString).postln; };
    };
};

OSCFunc.trace(true);
AppClock.sched(1.0, {
    var ok;
    ok = true;
    OSCFunc.trace(false);
    postStatus.value;
    ok;
});
)
