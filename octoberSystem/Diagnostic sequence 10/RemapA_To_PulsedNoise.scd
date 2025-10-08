// RemapA_To_PulsedNoise.scd
// v0.3.1
// MD 20251008-2056

(

Ndef(\chainA).set(\in, Ndef(\srcPulsedNoise7));
"A → srcPulsedNoise7".postln;
nil
)