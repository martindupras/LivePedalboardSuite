// NPBusShapeEnsurer.sc
// v0.1.0
// MD 20251011-2226

/*
Purpose:
- Ensure a NodeProxy (Ndef) has a given rate/width, with convenience for mono, stereo, hex.
- Exposes bus info for assertions in tests.
Style:
- var-first, lowercase names, explicit ^ returns in class methods.
*/

NPBusShapeEnsurer : Object {

    *new { ^super.new.init }

    init {
        ^this
    }

    ensureN { arg key, numChannels, rate = \audio;
        var proxyBus, needsInit;

        proxyBus = Ndef(key).bus;
        needsInit = proxyBus.isNil
            or: { proxyBus.rate != rate }
            or: { proxyBus.numChannels != numChannels };

        if(needsInit) {
            if(rate == \audio) {
                Ndef(key).ar(numChannels);
            } {
                Ndef(key).kr(numChannels);
            };
        };

        ^this
    }

    ensureMono { arg key, rate = \audio;
        this.ensureN(key, 1, rate);
        ^this
    }

    ensureStereo { arg key, rate = \audio;
        this.ensureN(key, 2, rate);
        ^this
    }

    ensureHex { arg key, rate = \audio;
        this.ensureN(key, 6, rate);
        ^this
    }

    busInfo { arg key;
        var bus, info;

        bus = Ndef(key).bus;
        info = IdentityDictionary[
            \key -> key,
            \exists -> bus.notNil,
            \rate -> (bus.notNil.if { bus.rate } { \none }),
            \numChannels -> (bus.notNil.if { bus.numChannels } { 0 })
        ];

        ^info
    }
}