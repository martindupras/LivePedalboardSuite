// Step2_Meters_InSinks.scd
// v0.3.0
// MD 20251008-2034

/* Purpose
- Re-define sinks to include SendPeakRMS inside the sink (preferred).
- A -> /peakrmsA id 2001; B -> /peakrmsB id 2002.
*/

(
var nothing;

Ndef(\chainA, {
    var x;
    x = \in.ar(0!2);
    SendPeakRMS.kr(x, 24, 3, '/peakrmsA', 2001);
    x
}).ar(2);

Ndef(\chainB, {
    var y;
    y = \in.ar(0!2);
    SendPeakRMS.kr(y, 24, 3, '/peakrmsB', 2002);
    y
}).ar(2);

"STEP 2: in-sink meters armed. Meters move when sinks play.".postln;
nil
)