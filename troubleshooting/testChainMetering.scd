// testChainMetering.scd
// v1
// MD 20251007-1003

// THIS IS ALL WORKING. This shows we can make two test melodies, route them to chains that are melody-> meter -> sink.


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

Ndef(\meterA, { var inSig;
	inSig = \in.ar(2);
	//SendPeakRMS.kr(sig:, rate:, peakLag:,  cmdName:'/peakrmsA',  replyId:3601);
	SendPeakRMS.kr(inSig, 3, 3, '/peakrmsA' ,  9876);
	inSig });

Ndef(\meterB, { var inSig;
	inSig = \in.ar(2);
	SendPeakRMS.kr(inSig, 3, 3, '/peakrmsB' ,  9877);
	inSig });

Ndef(\sinkA, { var inSig; inSig = \in.ar(2);       inSig });
Ndef(\sinkB, { var inSig; inSig = \in.ar(2);       inSig });

Ndef(\sinkA).play <<> Ndef(\meterA) <<> Ndef(\testmelodyA);
Ndef(\sinkB) <<> Ndef(\meterB) <<> Ndef(\testmelodyB);


// "SWITCH" to make chainB audible but not chainA
Ndef(\sinkA).stop;
Ndef(\sinkB).play;


// "SWITCH" to make chainA audible but not chainB
Ndef(\sinkB).stop;
Ndef(\sinkA).play;