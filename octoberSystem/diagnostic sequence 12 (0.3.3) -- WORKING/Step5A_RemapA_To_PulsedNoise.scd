// Step5A_RemapA_To_PulsedNoise.scd
// v0.3.3
// MD 20251008-2115
(
Ndef(\chainA).set(\in, Ndef(\srcPulsedNoise7));
"A → srcPulsedNoise7".postln;
)