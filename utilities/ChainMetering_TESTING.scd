// ChainMetering_TESTING.scd
// v1
// MD 20251007-1003




Ndef(\sinkA) <<> Ndef(\meterA) <<> Ndef(\testmelodyA);
Ndef(\sinkB) <<> Ndef(\meterB) <<> Ndef(\testmelodyB);


// "SWITCH" to B
Ndef(\sinkA).stop;
Ndef(\sinkB).play;


// "SWITCH" to A
Ndef(\sinkB).stop;
Ndef(\sinkA).play;


// set both sources to silent
Ndef(\sinkA) <<> Ndef(\meterA) <<> Ndef(\silent);
Ndef(\sinkB) <<> Ndef(\meterB) <<> Ndef(\silent);

Ndef(\sinkA) <<> Ndef(\meterA) <<> Ndef(\srcPink);

Ndef(\sinkB) <<> Ndef(\meterB) <<> Ndef(\srcPink);


Ndef(\sinkA) <<> Ndef(\meterA) <<> Ndef(\srcPink);

Ndef(\sinkB) <<> Ndef(\meterB) <<> Ndef(\srcPink).set(\amp,0.25); // <- set changes the volume at the SOURCE
Ndef(\sinkB) <<> Ndef(\meterB) <<> Ndef(\srcPink).set(\amp,0.025);

Ndef(\sinkA) <<> Ndef(\meterA) <<> Ndef(\srcSquare88);


// diagnostics

// Pink noise
Ndef(\srcPink).stop

// Square wave at 88 Hz
Ndef(\srcSquare88).stop;
Ndef(\srcSquare88).play;

// Pulse train at 134 Hz (narrow duty)
Ndef(\srcPulseTrain134).stop;

// Pulsed noise (white noise * sinusoid 7 Hz)
Ndef(\srcPulsedNoise7).stop;

// Random bleeps & bloops
Ndef(\srcBleeps).stop;

Ndef(\meterA) <<> Ndef(\srcSquare88);
Ndef(\meterA).play;
Ndef(\meterA).stop;

Ndef(\sinkA) <<> Ndef(\testmelodyA);
Ndef(\sinkA).play;
Ndef(\sinkB) <<> Ndef(\testmelodyB);








Ndef(\sinkA).set(\in, Ndef(\meterA).bus);
Ndef(\sinkA).play;
Ndef(\meterA).set(\in, Ndef(\testmelodyA).bus);