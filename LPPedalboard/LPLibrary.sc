// LPLibrary.sc (renamed from MagicProcessLibrary.sc)

// V1.0.4 added libPassthrough for testing
// v1.0.3 fixed this.register.(   to   this.register(
// v1.0.2 added class version stuff
// v1.0.1 add a listAvailable method

/*
   Holds a registry of processor/source functions and can ensure Ndefs exist.
*/
LPLibrary : Object {
	classvar version;

	var < defs;           // IdentityDictionary: Symbol -> Function
	var < defaultNumChannels;
	var < numChannels;

	*initClass {
		var text;
		version = "v1.0.4";
		text = "LPLibrary " ++ version;
		text.postln;
	}

	*new { ^super.new.init }

	init {
		defs = IdentityDictionary.new;
		defaultNumChannels = 2;
		numChannels = 2; // for now, eventually six.

		this.createNdefSpecs; // register all the processors

		// Do the stuff here:
		// register all the processors in the dictionary
		^this
	}

	register { arg key, func;
		defs[key] = func;
		^this
	}

	has { arg key;
		^defs.includesKey(key)
	}

	get { arg key;
		^defs[key]
	}

	keys { ^defs.keys }

	// Create or update an Ndef for key
	ensure { arg key, chans;
		var func, numCh, canRun;
		func = defs[key];
		if(func.isNil) { ^this }; // silently ignore if not registered
		numCh = chans ? NumChannels;
		canRun = Server.default.serverRunning;
		if(canRun) {
			Server.default.bind({
				Ndef(key, func);
				Ndef(key).ar(numCh);
			});
		};
		^this
	}

	// Ensure many keys at once
	ensureMany { arg keyArray, chans;
		keyArray.do({ arg key; this.ensure(key, chans) });
		^this
	}

	// Convenience: ensure whatever appears in a chain array
	ensureFromChain { arg chainArray, chans;
		var lastIndex, idx;
		if(chainArray.isNil or: { chainArray.size < 2 }) { ^this };
		lastIndex = chainArray.size - 1;
		idx = 0;
		while({ idx <= lastIndex }, {
			this.ensure(chainArray[idx], chans);
			idx = idx + 1;
		});
		^this
	}

	////////////////////////////////

	// MDNOTE: I'm rethinking this... since everything
	// ends up as Ndef, and we can make elastic Ndefs,
	// why not turn this into an Ndef maker? We define
	// the whole Ndef; we just need to instantiate a
	// new one with a new symbol every time.
	// PROS: easier to test, easier to maintain.

	createNdefSpecs{

		// Sources
		this.register(\ts0, {
			var inputSignal;
			inputSignal = Silent.ar((0..1));
			inputSignal * 1.0
		});

		this.register(\libPassthrough, {
			var sig;
			sig = \in.ar(0 ! numChannels);
			sig * 0.5
		});

		this.register(\TestPink, {
			var inputSignal;
			inputSignal = Silent.ar((0..1));
			inputSignal * 1.0
		});

		// Effects – same as in bootstrap, or your refined versions
		this.register(\delay, {
			var inputSignal, time, fb, mix, delayed;
			inputSignal = \in.ar;
			time = \time.kr(0.35).clip(0.01, 2.0);
			fb   = \fb.kr(0.35).clip(0.0, 0.95);
			mix  = \mix.kr(0.25).clip(0.0, 1.0);
			delayed = CombC.ar(inputSignal, 2.0, time, time * (fb * 6 + 0.1));
			XFade2.ar(inputSignal, delayed, (mix * 2 - 1))
		});

		this.register(\tremolo, {
			var inputSignal, rate, depth;
			inputSignal = \in.ar;
			rate  = \rate.kr(5).clip(0.1, 20);
			depth = \depth.kr(0.5).clip(0, 1);
			inputSignal * SinOsc.kr(rate).range(1 - depth, 1)
		});

		this.register(\reverb, {
			var inputSignal, mix, room, damp;
			inputSignal = \in.ar;
			mix  = \mix.kr(0.25).clip(0, 1);
			room = \room.kr(0.5).clip(0, 1);
			damp = \damp.kr(0.3).clip(0, 1);
			XFade2.ar(inputSignal, FreeVerb2.ar(inputSignal[0], inputSignal[1], mix, room, damp), 0)
		});

		this.register(\chorus, {
			var inputSignal, rate, depth, baseDelay, modDelay;
			inputSignal = \in.ar;
			rate      = \rate.kr(0.8).clip(0.1, 5);
			depth     = \depth.kr(0.008).clip(0.0, 0.02);
			baseDelay = \base.kr(0.020).clip(0.0, 0.05);
			modDelay  = baseDelay + (SinOsc.kr(rate, 0, depth));
			DelayC.ar(inputSignal, 0.1, modDelay)
		});

		this.register(\drive, {
			var inputSignal, gain;
			inputSignal = \in.ar;
			gain = \gain.kr(2.5).clip(1, 10);
			(inputSignal * gain).tanh
		});
	}
}
