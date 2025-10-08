// Step4A_Remap_A_to_PulsedNoise.scd
// v0.3.0
// MD 20251008-2034
(
var nothing;
Ndef(\chainA).set(\in, Ndef(\srcPulsedNoise7));
"A → srcPulsedNoise7".postln;
nil
)