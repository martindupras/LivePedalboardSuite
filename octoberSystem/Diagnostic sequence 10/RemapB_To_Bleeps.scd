// RemapB_To_Bleeps.scd
// v0.3.1
// MD 20251008-2056

(

Ndef(\chainB).set(\in, Ndef(\srcBleeps));
"B → srcBleeps".postln;
nil
)
