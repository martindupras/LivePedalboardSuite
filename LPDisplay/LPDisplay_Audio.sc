// LPDisplay_Audio.sc
// v0.9.8
+ LPDisplay{


	// install console RMS responders:
	installConsoleRespondersIfEnabled {
		var oldA, oldB, extract;
		// Free any previous console responders
		oldA = OSCdef(oscConsoleA); if (oldA.notNil) { oldA.free };
		oldB = OSCdef(oscConsoleB); if (oldB.notNil) { oldB.free };
		if (consoleLevelsOn.not) { ^this }; // nothing to install

		extract = { arg msg;
			var lin = 0.0, n = msg.size;
			if (n >= 4) { lin = msg[n-1].asFloat };
			lin.clip(0.0, 1.0)
		};

		OSCdef(oscConsoleA, { arg msg;
			var v;
			v = extract.value(msg).max(1e-6);
			("A level: " ++ v.ampdb.round(0.1) ++ " dB (" ++ v.round(0.003) ++ ")").postln;
		}, '/peakrmsA');

		OSCdef(oscConsoleB, { arg msg;
			var v;
			v = extract.value(msg).max(1e-6);
			("B level: " ++ v.ampdb.round(0.1) ++ " dB (" ++ v.round(0.003) ++ ")").postln;
		}, '/peakrmsB');

		^this
	}

	setConsoleLevelsOn { arg flag = false;
		consoleLevelsOn = flag.asBoolean;
		this.installConsoleRespondersIfEnabled;
		^this
	}



	setSourceA { |sourceSymbol|
		if (chainA.notNil) {
			chainA.setTailSource(sourceSymbol);
			{
				if (topLeftText.notNil) { topLeftText.string_(chainA.chainToString) };
			}.defer;
		};
		^this
	}

	setSourceB { |sourceSymbol|
		if (chainB.notNil) {
			chainB.setTailSource(sourceSymbol);
			{
				if (topRightText.notNil) { topRightText.string_(chainB.chainToString) };
			}.defer;
		};
		^this
	}





	bootAndBuildGraph {
		Server.default.waitForBoot({
			var extractLinearRmsFromOscMessage;
			this.defineDefaultSourcesAndSinks;

			// Initial chains
			chainA = LPDisplaySigChain.new([\outA, \srcA]).rebuild;
			chainB = LPDisplaySigChain.new([\outB, \srcB]).rebuild;

			// Show full chain strings in the GUI (nil-safe)
			{
				if (topLeftText.notNil)  { topLeftText.string_(chainA.chainToString) };
				if (topRightText.notNil) { topRightText.string_(chainB.chainToString) };
			}.defer;

			// Avoid duplicates on re-eval
			{ OSCdef(oscNameA).free; OSCdef(oscNameB).free; OSCdef(oscConsoleA).free; OSCdef(oscConsoleB).free; }.value;

			// Robust extraction: pick the last numeric in message (typically final RMS per SendPeakRMS)
			extractLinearRmsFromOscMessage = { |oscMessage|
				var linearRms = 0.0, messageSize;
				if (oscMessage.notNil) {
					messageSize = oscMessage.size;
					if (messageSize >= 4) { linearRms = oscMessage[messageSize - 1].asFloat };
				};
				linearRms.clip(0.0, 1.0)
			};

			// GUI meters (20 Hz), nil-safe; apply HUD mapping if present, else raw RMS
			OSCdef(oscNameA, { |oscMessage|
				var linearRms = extractLinearRmsFromOscMessage.(oscMessage);
				var meterValueUi = (meterHudMap.notNil).if({ meterHudMap.mapLinToUi(linearRms) }, { linearRms });
				{
					if (topLeftMeter.notNil) { topLeftMeter.value_(meterValueUi) };
				}.defer;
			}, '/peakrmsA');

			OSCdef(oscNameB, { |oscMessage|
				var linearRms = extractLinearRmsFromOscMessage.(oscMessage);
				var meterValueUi = (meterHudMap.notNil).if({ meterHudMap.mapLinToUi(linearRms) }, { linearRms });
				{
					if (topRightMeter.notNil) { topRightMeter.value_(meterValueUi) };
				}.defer;
			}, '/peakrmsB');

/*            // Console prints (~1 Hz via decimation), now gated by 'consoleLevelsOn'
            OSCdef(oscConsoleA, { |oscMessage|
                var linearRmsForConsole;
                if (consoleLevelsOn) {
                    if (firstDumpA) {
                        ("A first msg: %".format(oscMessage)).postln;
                        firstDumpA = false;
                    };
                    countA = countA + 1;
                    if (countA >= 20) {
                        linearRmsForConsole = extractLinearRmsFromOscMessage.(oscMessage).max(1e-6);
                        ("A level: " ++ (linearRmsForConsole.ampdb.round(0.1))
                            ++ " dB (" ++ linearRmsForConsole.round(0.003) ++ ")").postln;
                        countA = 0;
                    };
                } {
                    // printing disabled — keep counters steady or reset if you prefer
                    countA = 0;
                };
            }, '/peakrmsA');

            OSCdef(oscConsoleB, { |oscMessage|
                var linearRmsForConsole;
                if (consoleLevelsOn) {
                    if (firstDumpB) {
                        ("B first msg: %".format(oscMessage)).postln;
                        firstDumpB = false;
                    };
                    countB = countB + 1;
                    if (countB >= 20) {
                        linearRmsForConsole = extractLinearRmsFromOscMessage.(oscMessage).max(1e-6);
                        ("B level: " ++ (linearRmsForConsole.ampdb.round(0.1))
                            ++ " dB (" ++ linearRmsForConsole.round(0.003) ++ ")").postln;
                        countB = 0;
                    };
                } {
                    // printing disabled — keep counters steady or reset if you prefer
                    countB = 0;
                };
            }, '/peakrmsB');*/
		});
		^this
	}

	defineDefaultSourcesAndSinks {
		// SOURCES (stereo)
		Ndef(\srcZ, { Silent.ar(numChannels: 2) });
		Ndef(\srcA, { PinkNoise.ar(0.10 ! 2) });
		Ndef(\srcB, { SinOsc.ar([300, 301], mul: 0.20) });
		Ndef(\srcC, { LFSaw.ar([167, 171]).tanh * 0.18 });

		// SINKS (\in.ar(2)) + SendPeakRMS (A=1, B=2)
		// Note on replyID: A=1 and B=2 are kept intentionally for continuity with earlier dumps/log parsers.
		// The OSC addresses also differ (/peakrmsA vs /peakrmsB), so replyID isn't strictly required,
		// but keeping these IDs preserves compatibility with prior tools and logs.
		Ndef(\outA, {
			var sig = \in.ar(2);
			SendPeakRMS.kr(sig, 20, 3, '/peakrmsA', 1); // replyID 1 == chain A
			sig
		});
		Ndef(\outB, {
			var sig = \in.ar(2);
			SendPeakRMS.kr(sig, 20, 3, '/peakrmsB', 2); // replyID 2 == chain B
			sig
		});
		^this
	}


}