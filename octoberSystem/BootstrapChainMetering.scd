// testChainMetering.scd
// v1
// MD 20251007-1003

// THIS IS ALL WORKING. This shows we can make two test melodies, route them to chains that are melody-> meter -> sink.

/*
 IMPORTANT DISCOVERY:

       \in.ar(0!2)
            is the correct form; it defaults \in to a stereo array of zeroes
        \in.ar(2) <--- is BAD! defaults to a stream of 2s. Not what we want!

*/

//----------------
// Tests signals:
//----------------
Ndef(\sinkA).ar(2); // initialises stereo
Ndef(\sinkB).ar(2);
Ndef(\meterA).ar(2);
Ndef(\meterB).ar(2);

Ndef(\silence, { Silent.ar(2) }).numChannels.postln;


// Pink noise
Ndef(\srcPink, { PinkNoise.ar(1 ! 2) * \amp.kr(0.125).clip(0.0, 1.0); }).numChannels.postln;

// Square wave at 88 Hz
Ndef(\srcSquare88, { Pulse.ar(88, 0.5) ! 2 * \amp.kr(0.125).clip(0.0, 1.0); }).numChannels.postln;

// Pulse train at 134 Hz (narrow duty)
Ndef(\srcPulseTrain134, { LFPulse.ar(134, 0, 0.12) ! 2 * \amp.kr(0.125).clip(0.0, 1.0); }).numChannels.postln;

// Pulsed noise (white noise * sinusoid 7 Hz)
Ndef(\srcPulsedNoise7, {
    WhiteNoise.ar(1 ! 2) * SinOsc.kr(7).range(0, 1) * \amp.kr(0.125).clip(0.0, 1.0);
}).numChannels.postln;

// Random bleeps & bloops
Ndef(\srcBleeps, {
    var trig = Dust.kr(3);
    var freq = TExpRand.kr(180, 2800, trig);
    var env = Decay2.kr(trig, 0.005, 0.20);
    var tone = SinOsc.ar(freq + TRand.kr(-6, 6, trig));
    var sig = RLPF.ar(tone, (freq * 2).clip(80, 9000), 0.25) * env;
    Pan2.ar(sig * \amp.kr(0.125).clip(0.0, 1.0), LFNoise1.kr(0.3).range(-0.6, 0.6));
}).numChannels.postln;


//----------------
// Test melodies
//----------------
Ndef(\testmelodyA, {
                var t = Impulse.kr(2.2);
                var e = Decay2.kr(t, 0.01, 0.30);
                var f = Demand.kr(t, 0, Dseq([220, 277.18, 329.63, 392], inf));
                (SinOsc.ar(f) * e * 0.22)!2
            });


            Ndef(\testmelodyB, {
                var t = Impulse.kr(3.1);
                var e = Decay2.kr(t, 0.02, 0.18);
                var f = Demand.kr(t, 0, Dseq([392, 329.63, 246.94, 220, 246.94], inf));
                (Pulse.ar(f, 0.35) * e * 0.20)!2
            });

//----------------
// Meters
//----------------
Ndef(\meterA, { var inSig;
	inSig = \in.ar(0!2);
	//SendPeakRMS.kr(sig:, rate:, peakLag:,  cmdName:'/peakrmsA',  replyId:3601);
	SendPeakRMS.kr(inSig, 20, 3, '/peakrmsA' ,  9876);
	inSig }).numChannels.postln;

Ndef(\meterB, { var inSig;
	inSig = \in.ar(0!2);
	SendPeakRMS.kr(inSig, 20, 3, '/peakrmsB' ,  9877);
	inSig }).numChannels.postln;

//----------------
// Sinks
//----------------

Ndef(\sinkA, { var inSig; inSig = \in.ar(0!2);       inSig }).numChannels.postln;
Ndef(\sinkB, { var inSig; inSig = \in.ar(0!2);       inSig }).numChannels.postln;

//////////////////////////////
// ----------- default chains
// comment out if not wanted, or set the beginning to Ndef(\silence)

Ndef(\sinkA) <<> Ndef(\meterA) <<> Ndef(\testmelodyA);
Ndef(\sinkB) <<> Ndef(\meterB) <<> Ndef(\testmelodyB);


//////////////////////////////

// TESTING CODE - uncomment and evalute line by line
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
*/