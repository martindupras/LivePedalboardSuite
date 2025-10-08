// Step5_Cleanup_StopAll.scd
// v0.3.0
// MD 20251008-2034
(
var nothing;
Ndef(\chainA).stop;
Ndef(\chainB).stop;
"Stopped A and B.".postln;
nil
)