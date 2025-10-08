// StepE_MapAltSources.scd
// v0.0.1
// MD 20251008-1734

/* Purpose
- Convenience lines to remap chain inputs to other test sources.
- Evaluate the specific line(s) you need.
*/

(
// Map A -> pulsed noise
var nothing;
Server.default.bind({ Ndef(\chainA).map(\in, Ndef(\srcPulsedNoise7)) });
nil
)

// -- or --

// Map B -> bleeps
(
var nothing;
Server.default.bind({ Ndef(\chainB).map(\in, Ndef(\srcBleeps)) });
nil
)
