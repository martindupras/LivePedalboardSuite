// Stop_All_TestSounds.scd
// v0.1.0
// MD 20251003-1302

/* Purpose/Style:
- Stop any test synths safely by freeing default group.
- No server.sync; posts what it did.
*/

(
var freed;

freed = s.serverRunning.if({
    s.defaultGroup.freeAll;
    "Freed all synths in default group.".postln;
    true
}, {
    "Server not running; nothing to free.".postln;
    false
});

freed
)