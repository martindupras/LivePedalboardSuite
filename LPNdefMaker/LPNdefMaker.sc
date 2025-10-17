// LPNdefMaker.sc

// v0.6.0.1 tidy (removed commented-out code))
// v0.6 new version, simpler -- seems to work!
// v0.1 starting from LPLibrary as base

/*

Let's work this out: 
we give this class two arguments: the name of an Ndef recipe, and a name 
for it. (Let's assume that the caller is keeping track such that if we
call \tremolo, we might give it name \tremolo01 and keep a record of
that unique name at the caller level.)

This class needs to know about the Ndef recipes so internally we keep them 
all in a dictionary, which we populate at init by calling setup fxLib (dumb 
name but let's use for now.))

init: populate dictionary of recipes ("defs")

[DONE] create: make an Ndef with the given name, using the recipe from the dictionary.
[DONE] clear: free the Ndef with the given name.
[DONE] keys: list all the registered recipes.

HAVE A PLAN for keeping the Ndefs in external files and loading them them up as needed.


*/

LPNdefMaker : Object {
    classvar version;
    var < defs; // IdentityDictionary: Symbol -> Function
    // var <defaultNumChannels; not sure we need this now
    var < numChannels;

    *initClass {
        version = "v0.6";
        ("LPNdefMaker " ++ version).postln;
    }

    *new { ^super.new.init }

    init {

		numChannels = 2;  // Eventually we want the numChannels to come from LPOrchestrator; pass as argument?

        defs = IdentityDictionary.new; // keep the Ndef "recipes"

        this.createNdefSpecs; // put the recipes in the dictionary

		^this
    }

    register { arg key, audioFunction;
        defs[key] = audioFunction;
        ^this
    }

    has { arg key;
        ^defs.includesKey(key)
    }

    get { arg key;
        ^defs[key]
    }

    keys { ^defs.keys }

    create { arg recipeKey, instanceKey;
        var audioFunction;
        audioFunction = defs[recipeKey];
        if (audioFunction.isNil) {
            ("Recipe not found: " ++ recipeKey).warn;
            ^nil;
        };

		// WHY WOULD WE NEED THIS HERE?
        if (Server.default.serverRunning) { // if server is running...
            Server.default.bind({ // then safely invoke Ndef creation on server thread; not entirely sure this is needed but probably doesn't hurt.
                Ndef(instanceKey, audioFunction);
            });
        };
        ^instanceKey // should do for now -- but want to keep internal register with unique names
    }

    clear { arg instanceKey;

        Ndef(instanceKey).clear;
        ^this
    }

    createNdefSpecs {

		// Sources
		this.register(\ts0, {
			var inputSignal;
			inputSignal = Silent.ar((0!numChannels)); // stereo silence
			inputSignal * 1.0
		});

		this.register(\libpassthrough, {
			var sig;
			sig = \in.ar(0 ! numChannels);
			sig * 0.5
		});

		this.register(\testpink, {
			var inputSignal;
			inputSignal = PinkNoise.ar((0.1)!numChannels);
			inputSignal * 1.0
		});

		// Effects – same as in bootstrap, or your refined versions
		this.register(\delay, {
			var inputSignal, time, fb, mix, delayed;
			inputSignal = \in.ar(0 ! numChannels);
			time = \time.kr(0.35).clip(0.01, 2.0);
			fb   = \fb.kr(0.35).clip(0.0, 0.95);
			mix  = \mix.kr(0.25).clip(0.0, 1.0);
			delayed = CombC.ar(inputSignal, 2.0, time, time * (fb * 6 + 0.1));
			XFade2.ar(inputSignal, delayed, (mix * 2 - 1))
		});

		this.register(\tremolo, {
			var inputSignal, rate, depth;
			inputSignal = \in.ar(0 ! numChannels);
			rate  = \rate.kr(5).clip(0.1, 20);
			depth = \depth.kr(0.5).clip(0, 1);
			inputSignal * SinOsc.kr(rate).range(1 - depth, 1)
		});

		this.register(\reverb, {
			var inputSignal, mix, room, damp;
			inputSignal = \in.ar(0 ! numChannels);
			mix  = \mix.kr(0.25).clip(0, 1);
			room = \room.kr(0.5).clip(0, 1);
			damp = \damp.kr(0.3).clip(0, 1);
			XFade2.ar(inputSignal, FreeVerb2.ar(inputSignal[0], inputSignal[1], mix, room, damp), 0)
		});

		this.register(\chorus, {
			var inputSignal, rate, depth, baseDelay, modDelay;
			inputSignal = \in.ar(0 ! numChannels);
			rate      = \rate.kr(0.8).clip(0.1, 5);
			depth     = \depth.kr(0.008).clip(0.0, 0.02);
			baseDelay = \base.kr(0.020).clip(0.0, 0.05);
			modDelay  = baseDelay + (SinOsc.kr(rate, 0, depth));
			DelayC.ar(inputSignal, 0.1, modDelay)
		});

		this.register(\drive, {
			var inputSignal, gain;
			inputSignal = \in.ar(0 ! numChannels);
			gain = \gain.kr(2.5).clip(1, 10);
			(inputSignal * gain).tanh
		});
	}
}