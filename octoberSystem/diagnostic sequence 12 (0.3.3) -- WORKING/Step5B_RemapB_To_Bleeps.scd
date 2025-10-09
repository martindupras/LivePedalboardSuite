// Step5B_RemapB_To_Bleeps.scd
// v0.3.3
// MD 20251008-2115
(
Ndef(\chainB).set(\in, Ndef(\srcBleeps));
"B → srcBleeps".postln;
)