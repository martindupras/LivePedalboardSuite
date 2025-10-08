// Step4B_Remap_B_to_Bleeps.scd
// v0.3.2
// MD 20251008-2106
(
Ndef(\chainB).set(\in, Ndef(\srcBleeps));
"B → srcBleeps".postln;
)