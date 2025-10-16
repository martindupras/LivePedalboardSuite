// NewPedalboardCandidateA.sc
// v0.1.4
// MD 20251011-2207

/*
Purpose:
- Minimal A/B pedalboard manager with an active output.
- Default '\internalGenerators' mode uses built-in test signals for A and B.
- Chains are lists [sinkOut, chainIn]; we connect using Ndef(left) <<> Ndef(right).
Style:
- var-first, lowercase names, explicit ^ returns in class methods, no server.sync.
*/

NewPedalboardCandidateA : Object {

	// ── instance state ───────────────────────────────────────────
	var <defaultNumChannels;
	var <sourceMode;          // \internalGenerators or \audioHardwareInputs
	var <chainAList;          // [\chainAOut, \chainAIn]
	var <chainBList;          // [\chainBOut, \chainBIn]
	var <activeSinkKey;       // \chainAOut or \chainBOut

	// ── construction ─────────────────────────────────────────────
	*new { arg source = \internalGenerators;
		^super.new.init(source)
	}

	init { arg source = \internalGenerators;
		var mode;

		defaultNumChannels = 2;
		mode = source.asSymbol;   // \internalGenerators or \audioHardwareInputs

		this.ensureServerReady;

		// Remember mode; branch to internal generators vs hardware input.
		this.setInternalSources(mode);
		if(mode == \internalGenerators) {
			this.setNdefGenerators;
		} {
			this.setupAudioHardwareInputs;
		};

		// Create the basic pedalboard nodes: chainAIn/BIn, chainAOut/BOut, and activeOut.
		this.setupNdefPedalboard;

		// Initial chain lists: OUT feeds from IN for each side.
		chainAList = [\chainAOut, \chainAIn];
		chainBList = [\chainBOut, \chainBIn];

		// Wire both chains (simple 2-node connections for now).
		this.rebuildChain(chainAList);
		this.rebuildChain(chainBList);

		// Make chain A the audible chain by feeding it into activeOut and playing activeOut.
		this.makeChainActive(\chainAOut);

		^this
	}

	// ── server bring-up (small, guarded; no server.sync) ─────────
	ensureServerReady {
		var serverRef;

		serverRef = Server.default;

		if(serverRef.serverRunning.not) {
			serverRef.waitForBoot({
				serverRef.bind({
					serverRef.initTree;
					serverRef.defaultGroup.freeAll;
				});
			});
		} {
			serverRef.bind({
				// Keep current tree; placeholder to ensure default group exists.
				0;
			});
		};

		^this
	}

	// ── mode & sources ───────────────────────────────────────────
	setInternalSources { arg mode;
		// default to \internalGenerators if nil; normalize to Symbol just in case
		sourceMode = (mode ? \internalGenerators).asSymbol;
		^this
	}

	// Internal test generators (very small; stereo-safe)
	setNdefGenerators {
		var chans;

		chans = defaultNumChannels;

		Ndef(\chainAIn, {
			var trig, env, freq, wave, sig;
			trig = Impulse.kr(2.0);
			env  = Decay2.kr(trig, 0.01, 0.30);
			freq = Demand.kr(trig, 0, Dseq([220, 277.18, 329.63, 392], inf));
			wave = SinOsc.ar(freq);
			sig  = wave * env * 0.22;
			sig ! chans
		});

		Ndef(\chainBIn, {
			var trig, env, freq, wave, sig;
			trig = Impulse.kr(3.1);
			env  = Decay2.kr(trig, 0.02, 0.18);
			freq = Demand.kr(trig, 0, Dseq([392, 329.63, 246.94, 220, 246.94], inf));
			wave = Pulse.ar(freq, 0.35);
			sig  = wave * env * 0.20;
			sig ! chans
		});

		^this
	}

	// Placeholder for future hardware inputs (kept silent for now)
	// Used when sourceMode == \audioHardwareInputs

//older:
/*    setupAudioHardwareInputs {
        var chans;

        chans = defaultNumChannels;

        Ndef(\chainAIn, { Silent.ar(chans) });
        Ndef(\chainBIn, { Silent.ar(chans) });

        ^this
    }*/


	//revised:

	setupAudioHardwareInputs {
		var chans;

		chans = defaultNumChannels;

		// Hardware inputs; keep both chain inputs live.
		Ndef(\chainAIn, { SoundIn.ar(chans) });
		Ndef(\chainBIn, { SoundIn.ar(chans) });

		^this
	}



	// ── pedalboard node creation ─────────────────────────────────
	setupNdefPedalboard {
		var chans;

		chans = defaultNumChannels;

		// Sinks consume embedded input; keep shape pinned to stereo.
		Ndef(\chainAOut, { \in.ar(chans) });
		Ndef(\chainBOut, { \in.ar(chans) });
		Ndef(\activeOut, { \in.ar(chans) });

		// Ensure buses exist and are audio-rate for all base nodes.
		this.ensureStereoInternal(\chainAIn);
		this.ensureStereoInternal(\chainBIn);
		this.ensureStereoInternal(\chainAOut);
		this.ensureStereoInternal(\chainBOut);
		this.ensureStereoInternal(\activeOut);

		^this
	}

	// Ensure Ndef proxy is \audio, stereo (pattern borrowed from LPPedalboard)
	ensureStereoInternal { arg key;
		var proxyBus, needsInit, chans;

		chans = defaultNumChannels;
		proxyBus = Ndef(key).bus;
		needsInit = proxyBus.isNil
		or: { proxyBus.rate != \audio }
		or: { proxyBus.numChannels != chans };

		if(needsInit) {
			Ndef(key).ar(chans);
		};

		^this
	}

	// ── rebuild chain connection ─────────────────────────────────
	rebuildChain { arg chainList;
		var effective, indexCounter, leftKey, rightKey;

		effective = chainList; // no bypassing yet; two-symbol list

		effective.do({ arg keySymbol;
			this.ensureStereoInternal(keySymbol);
		});

		indexCounter = 0;
		while({ indexCounter < (effective.size - 1) }, {
			leftKey  = effective[indexCounter];
			rightKey = effective[indexCounter + 1];
			Ndef(leftKey) <<> Ndef(rightKey);
			indexCounter = indexCounter + 1;
		});

		^this
	}

	// ── activation / switching ───────────────────────────────────
	makeChainActive { arg outKey;
		var chans;

		chans = defaultNumChannels;

		// Feed the chosen chain's OUT into activeOut and play activeOut.
		Ndef(\activeOut) <<> Ndef(outKey);
		Ndef(\activeOut).mold(chans, \audio);

		if(Ndef(\activeOut).isPlaying.not) {
			Ndef(\activeOut).play(numChannels: chans);
		};

		activeSinkKey = outKey;

		^this
	}

	switch {
		var nextKey;

		nextKey = if(activeSinkKey == \chainAOut) { \chainBOut } { \chainAOut };
		this.makeChainActive(nextKey);

		^this
	}
}