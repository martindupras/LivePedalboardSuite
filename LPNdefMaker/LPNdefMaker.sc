// LPNdefMaker.sc

// v0.6.3 configurable prefix for recipe keys; not using it right now
// v0.6.2 add prefix-stripping for recipe keys during symbol creation
// v0.6.1 keep track of created symbols and create unique symbols. Working!
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
    var < numChannels;

    // added v0.6.1 to keep track of created Ndef symbols
    var < createdSymbols; // Array of all created Ndef symbols
    var < symbolCounts;   // IdentityDictionary: recipeKey -> count

    // added v0.6.3 configurable prefix
    var < recipePrefix;

    *initClass {
        version = "v0.6.3";
        ("LPNdefMaker " ++ version).postln;
    }

    *new { ^super.new.init }

    init {
        numChannels = 2;  // Eventually we want the numChannels to come from LPOrchestrator; pass as argument?
        defs = IdentityDictionary.new; // keep the Ndef "recipes"

        createdSymbols = Array.new;
        symbolCounts = IdentityDictionary.new;

        // added v0.6.3 configurable prefix; but we're not using for now
        recipePrefix = ""; // default prefix

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

    create { | recipeKey |
        var baseKey, audioFunction, count, newSymbol;

        // strip prefix from incoming key
        baseKey = recipeKey.asString.replace(recipePrefix, "").asSymbol;

        audioFunction = defs[baseKey];
        if (audioFunction.isNil) {
            ("Recipe not found: " ++ baseKey).warn;
            ^nil;
        };

        count = symbolCounts[baseKey] ? 0;
        count = count + 1;
        symbolCounts[baseKey] = count;

        newSymbol = (baseKey.asString ++ count.asString.padLeft(3, "0")).asSymbol;

        if (Server.default.serverRunning) {
            Server.default.bind({
                Ndef(newSymbol, audioFunction);
            });
        };

        createdSymbols = createdSymbols.add(newSymbol);
        ^newSymbol
    }

    // create { | recipeKey |
    //     var fullKey, audioFunction, count, newSymbol;

    //     // prepend prefix to get full recipe key
    //     fullKey = (recipePrefix ++ recipeKey.asString).asSymbol;

    //     audioFunction = defs[fullKey];
    //     if (audioFunction.isNil) {
    //         ("Recipe not found: " ++ fullKey).warn;
    //         ^nil;
    //     };

    //     count = symbolCounts[fullKey] ? 0;
    //     count = count + 1;
    //     symbolCounts[fullKey] = count;

    //     newSymbol = (recipeKey.asString ++ count.asString.padLeft(3, "0")).asSymbol;

    //     if (Server.default.serverRunning) {
    //         Server.default.bind({
    //             Ndef(newSymbol, audioFunction);
    //         });
    //     };

    //     createdSymbols = createdSymbols.add(newSymbol);
    //     ^newSymbol
    // }

    // create { | recipeKey |
    //     var audioFunction, count, baseName, newSymbol;

    //     audioFunction = defs[recipeKey];
    //     if (audioFunction.isNil) {
    //         ("Recipe not found: " ++ recipeKey).warn;
    //         ^nil;
    //     };

    //     baseName = recipeKey.asString.replace(recipePrefix, "");

    //     count = symbolCounts[recipeKey] ? 0;
    //     count = count + 1;
    //     symbolCounts[recipeKey] = count;

    //     newSymbol = (baseName ++ count.asString.padLeft(3, "0")).asSymbol;

    //     if (Server.default.serverRunning) {
    //         Server.default.bind({
    //             Ndef(newSymbol, audioFunction);
    //         });
    //     };

    //     createdSymbols = createdSymbols.add(newSymbol);
    //     ^newSymbol
    // }

    clear { arg instanceKey;
        Ndef(instanceKey).clear;
        ^this
    }

    createdKeys {
        ^createdSymbols.copy
    }

    hasCreated { arg symbol;
        ^createdSymbols.includes(symbol)
    }

    createNdefSpecs {

        // Sources
        this.register(\drive, {
            var inputSignal, gain;
            inputSignal = \in.ar(0 ! numChannels);
            gain = \gain.kr(2.5).clip(1, 10);
            (inputSignal * gain).tanh
        });

        this.register(\tremolo, {
            var inputSignal, rate, depth;
            inputSignal = \in.ar(0 ! numChannels);
            rate  = \rate.kr(5).clip(0.1, 20);
            depth = \depth.kr(0.5).clip(0, 1);
            inputSignal * SinOsc.kr(rate).range(1 - depth, 1)
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

        this.register(\reverb, {
            var inputSignal, mix, room, damp;
            inputSignal = \in.ar(0 ! numChannels);
            mix  = \mix.kr(0.25).clip(0, 1);
            room = \room.kr(0.5).clip(0, 1);
            damp = \damp.kr(0.3).clip(0, 1);
            XFade2.ar(inputSignal, FreeVerb2.ar(inputSignal[0], inputSignal[1], mix, room, damp), 0)
        });

        this.register(\delay, {
            var inputSignal, time, fb, mix, delayed;
            inputSignal = \in.ar(0 ! numChannels);
            time = \time.kr(0.35).clip(0.01, 2.0);
            fb   = \fb.kr(0.35).clip(0.0, 0.95);
            mix  = \mix.kr(0.25).clip(0.0, 1.0);
            delayed = CombC.ar(inputSignal, 2.0, time, time * (fb * 6 + 0.1));
            XFade2.ar(inputSignal, delayed, (mix * 2 - 1))
        });

        this.register(\testpink, {
            var inputSignal;
            inputSignal = PinkNoise.ar((0.1)!numChannels);
            inputSignal * 1.0
        });

        this.register(\libpassthrough, {
            var sig;
            sig = \in.ar(0 ! numChannels);
            sig * 0.5
        });

        this.register(\ts0, {
            var inputSignal;
            inputSignal = Silent.ar((0!numChannels)); // stereo silence
            inputSignal * 1.0
        });
    }
}