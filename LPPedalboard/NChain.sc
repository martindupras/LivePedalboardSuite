// NChain.sc

// v0.4 design the methods to add and remove effects and print chain
// v0.3 add a dummy insert method that makes a compound symbol for the inserts Ndef
// v0.2 added nameSymbol argument; works great!
// v0.1 working
// MD 20251012

/*

V0.2 Works great. Tets with testNChain.scd v0.2
V0.1 Seems to be working. Test with testNChain.scd v0.1

*/
NChain {
    classvar version;
    classvar defaultNumChannels;

    var chainName;

    *initClass {
        var text;
        version = "v0.3";            
        defaultNumChannels = 2; // Set a sensible default

        text = "Nchains " ++ version;
        text.postln;
    }

    *new  { |name| ^super.new.init(name) }

    init { |name = "defaultChain" |
        // var chainIn, chainOut;
        chainName = name.asString; // store the name as String
        this.makePassthrough(chainName.asSymbol); // just to test the method

        ^this
    }

    makePassthrough { |name = "defaultChain"|
       Ndef(name.asSymbol).reshaping_(\elastic).source = {
        // Read the audio input named \in with an explicit width.
        // Pick a width that covers your expected max (e.g., 6 for hex).
        \in.ar(0 ! 6)   // returns silent zeros on channels with no signal
       };
       ^this
    }

    insert  { |argName|
  
        // This will create a new Ndef and add it in the right place. We will need to keep track of what is conencted so that anything that was connected to chainName goes into the new thing and the new thing gets connected to the chain.
    
        var newName = chainName ++ argName.asString; // keep everything as string for now
        var newSymbol = newName.asSymbol;

        // we may have an instance variable that is keeping the name of the last Ndef; nil if there isn't one

        // if no effect (just insert passthrough):
            // this.makePassthrough(newName);
            // (1) connect existing to this one -- HOW DO WE FIND OUT?
            
            // (2) connect this one to chainName
             // Ndef(\chainName).source = { Ndef(newName.asSymbol).ar }; // something like this
             //




       /* DEBUGGING -- working now. 
        ("inside add method of NChain " ++ chainName).postln;
        postln("string: " + newName);
        postln("symbol" + newSymbol);
        */

        ^this
    }

    remove {
        // this would disconnect the last Ndef in the chain and (possibly) free (clear?) it.

        // (1) connect penultimate to chainname
        // (2) free last Ndef
        ^this
    }

    printChain{
        // this method would print out what Ndefs make up the chain printed to the console
        ^this
    }

    getChainList{
        // this method would return a list of the Ndef symbol names in order
        ^this
    }

}