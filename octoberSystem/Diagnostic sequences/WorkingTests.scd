// WorkingTests.scd

//these work:
Ndef(\srcBleeps).play;
Ndef(\srcBleeps).stop

Ndef(\srcPulsedNoise7).play;
Ndef(\srcPulsedNoise7).stop;

Ndef(\passthrough, {\in.ar(0!2) });


Ndef(\passthrough).play.set(\in, Ndef(\srcBleeps));
Ndef(\passthrough).stop;

Ndef(\passthrough).play.set(\in, Ndef(\srcPulsedNoise7));
Ndef(\passthrough).stop;