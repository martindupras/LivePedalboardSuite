// Step1_DefineSinks_Meters_Wire_NoPlay.scd
// v0.3.3
// MD 20251008-2115

(
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

// wire inputs (no play)
Ndef(\chainA).set(\in, Ndef(\testmelodyA));
Ndef(\chainB).set(\in, Ndef(\testmelodyB));

Ndef(\chainA).stop;  // silence baseline
Ndef(\chainB).stop;

"STEP 1: sinks defined (A=2001, B=2002), inputs wired, silent.".postln;
)