// Step3B_Switch_To_B.scd
// v0.3.0
// MD 20251008-2034

/* Purpose: stop A, play B (audible). */
(
var nothing;
Ndef(\chainA).stop;
Ndef(\chainB).play;
"AUDIBLE: B".postln;
nil
)