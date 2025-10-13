// NChain.sc
// v0.2 added nameSymbol argument
// v0.1 working
// MD 20251012


/*
Seems to be working. Test with testNChain.scd v0.1

*/
NChain {
    classvar version;
    classvar defaultNumChannels;

    *initClass {
        var text;
        version = "v0.2";            
        defaultNumChannels = 2; // Set a sensible default

        text = "Nchains " ++ version;
        text.postln;
    }

    *new  { |nameSymb| ^super.new.init(nameSymb) }

    init { |nameSymb = \defaultChain|
        // var chainIn, chainOut;

        this.makePassthrough(nameSymb); // just to test the method


        ^nil // no need to return anything, Ndefs should exist now
    }

    makePassthrough { |nameSymbol = \defaultPassthrough|
       Ndef(nameSymbol).reshaping_(\elastic).source = {
        // Read the audio input named \in with an explicit width.
        // Pick a width that covers your expected max (e.g., 6 for hex).
        \in.ar(0 ! 6)   // returns silent zeros on channels with no signal
       };
       ^nil // should we actually return somthing? The ndef exists now
    }
}