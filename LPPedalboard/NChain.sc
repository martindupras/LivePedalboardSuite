// NChain.sc

// v0.4.3 added printChain, getChainList and getChainAsArrayOfSymbols methods

// v0.4.2 adding init stuff to make sink and add to the chainList
// v0.4.1 added chainList List to keep track of the Ndefs in the chain. Any time we do something we will do it first, and if successul we'll make the same (insert, delete) into the chain.
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
	var chainNameSym;
	var numChannels;
	var chainList; // this will be a list of the Ndef names in the chain in order

	*initClass {
		var text;
		version = "v0.4.2";
		defaultNumChannels = 2; // Set a sensible default

		text = "Nchains " ++ version;
		text.postln;
	}

	*new  { |name| ^super.new.init(name) }

	init { |name = "defaultChain" |
		// var chainIn, chainOut;
		chainName = name.asString; // store the name as String
		chainNameSym = chainName.asSymbol; // and as Symbol... possibly not needed. Belt and braces.
		numChannels = defaultNumChannels; // could add as argument later
		chainList = List.new; // start with an empty list

		// add single passthrough Ndef
		//        this.makePassthrough(chainName.asSymbol); // just to test the method

		Ndef(chainNameSym).reshaping_(\elastic).source = {
			\in.ar(0 ! numChannels)   // instance width, not a hard-coded 6
		};
		// and add it to the chainList
		chainList.add(chainNameSym); // add the name of the chain to the list

        // console report:
        ("NChain init: name=" ++ chainName
        ++ " sink=" ++ chainNameSym
        ++ " channels=" ++ numChannels).postln;


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
        var names, line;

        // make sure we have a list; print empty cleanly
        if (chainList.isNil or: { chainList.isEmpty }) {
            ("NChain '" ++ chainName ++ "' chain = <empty>").postln;
            ^this
        };

        names = chainList.collect(_.asString); // collact the names as strings
        line = "NChain '" ++ chainName ++ "' chain = " ++ names.join("  <<>  "); // join with '<<>'
        line.postln;


		^this
	}


    /* ---------------
generated:
    printChain { |detailed = false|
        var names, pieces, line;

        // make sure we have a list; print empty cleanly
        if (chainList.isNil or: { chainList.isEmpty }) {
            ("NChain '" ++ chainName ++ "' chain = <empty>").postln;
            ^this
        };

        if (detailed.not) {
            // brief: \dest  <<>  \beta  <<>  \alpha  <<>  \source
            names = chainList.collect(_.asString);
            line = "NChain '" ++ chainName ++ "' chain = " ++ names.join("  <<>  ");
            line.postln;
            ^this
        } {
            // detailed: \dest[2|elastic]  <<>  \beta[2|elastic] ...
            pieces = chainList.collect { |sym|
                var nd, width, reshape, label;
                nd = Ndef(sym);
                width = nd.numChannels ? 0;           // 0 if not yet built
                reshape = nd.reshaping ? 'none';      // e.g. \elastic or 'none'
                label = sym.asString
                    ++ "[" ++ width.asString
                    ++ "|" ++ reshape.asString ++ "]";
                label
            };
            line = "NChain '" ++ chainName ++ "' chain = " ++ pieces.join("  <<>  ");
            line.postln;
            ^this
        };
    }

    getChainList {
        // return a defensive copy of the internal List (still a List)
        ^(chainList.isNil.if({ List.new }, { chainList.copy }))
    }

    getChainAsArrayOfSymbols {
        // optional: return as an Array of Symbols
        ^(chainList.isNil.if({ #[] }, { chainList.asArray }))
    }
    --------------- */
	getChainList {
        // returns a list
		^(chainList.isNil.if({ List.new }, { chainList.copy }))
	}

    getChainAsArrayOfSymbols {
        // return as an Array of Symbols
        ^(chainList.isNil.if({ #[] }, { chainList.asArray }))
    }
}