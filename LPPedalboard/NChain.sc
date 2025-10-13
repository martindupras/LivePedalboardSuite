// NChain.sc
// v0.0.2
// MD 20251012

NChain {
classvar version;
classvar defaultNumChannels;

 *initClass {
        var text;
        version = "v0.0.2";            
        defaultNumChannels = 2; // Set a sensible default

        text = "Nchains " ++ version;
        text.postln;
    }

    *new  { ^super.new.init }

    init {
        // var chainIn, chainOut;

        this.makePassthrough(\testChain); // just to test the method
       
        // Ndef(\chainIn).reshaping = \elastic; // let's try this for now; Ndef adopts channel count of source
        // Ndef(\chainOut).reshaping = \elastic;
        // Ndef(\chainIn, {In.ar(0!defaultNumChannels)});
        // Ndef(\chainOut, {In.ar(0!defaultNumChannels)});

        // this.ensureStereoInternal(\chainIn);
        // this.ensureStereoInternal(\chainOut); 

        ^nil // no need to return anything, Ndefs should exist now
    }

    // possibly not needed with elastic reshaping
    ensureStereoInternal { arg key;
        var proxyBus, needsInit;
        proxyBus = Ndef(key).bus;
        needsInit = proxyBus.isNil or: { proxyBus.rate != \audio } or: { proxyBus.numChannels != defaultNumChannels };
        if(needsInit) {
            Ndef(key).ar(defaultNumChannels);
        };
        ^nil 
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