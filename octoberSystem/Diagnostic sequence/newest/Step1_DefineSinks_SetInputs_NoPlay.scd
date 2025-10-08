// Step1_DefineSinks_SetInputs_NoPlay.scd
// v0.3.0
// MD 20251008-2034

/* Purpose
- Define chainA/chainB as pass-through sinks (\in.ar(0!2)) and wire inputs.
- Do NOT play sinks yet.
*/

(
var nothing;

Ndef(\chainA, { var x; x = \in.ar(0!2); x }).ar(2);
Ndef(\chainB, { var y; y = \in.ar(0!2); y }).ar(2);
Ndef(\chainA).set(\in, Ndef(\testmelodyA));
Ndef(\chainB).set(\in, Ndef(\testmelodyB));
"STEP 1: sinks defined; inputs wired; still silent.".postln;
nil
)