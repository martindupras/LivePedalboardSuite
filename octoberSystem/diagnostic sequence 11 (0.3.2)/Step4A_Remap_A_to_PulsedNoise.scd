// Step4A_Remap_A_to_PulsedNoise.scd
// v0.3.2
// MD 20251008-2106
(
Ndef(\chainA).set(\in, Ndef(\srcPulsedNoise7));
"A → srcPulsedNoise7".postln;
)