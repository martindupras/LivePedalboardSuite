// Step4B_Remap_B_to_Bleeps.scd
// v0.3.0
// MD 20251008-2034
(
var nothing;
Ndef(\chainB).set(\in, Ndef(\srcBleeps));
"B → srcBleeps".postln;
nil
)
