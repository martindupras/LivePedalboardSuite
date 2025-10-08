// Step3A_Activate_A.scd
// v0.3.0
// MD 20251008-2034

/* Purpose: stop B, play A (audible). */
(
var nothing;
Ndef(\chainB).stop;
Ndef(\chainA).play;
"AUDIBLE: A".postln;
nil
)