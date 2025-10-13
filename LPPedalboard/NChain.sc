// NChain.sc

// v0.4.6.9 add removeNewest method
// v0.4.6.8 remove commented out and tidy
// v0.4.6.7 add insertTest method that adds a -6dB passthrough stage for testing
// v0.4.6.6 now works (still not doing much.) init and rewireChain are doing what they should.
// v0.4.6.5 For clarity, now storing storing symbols (not string) into chainList and fullchainList
// v0.4.6.4 rewireChain going back to original strategy of copy chainList into fullchainList, add in and out, connect all together in turns.
// v0.4.6.3 fixed some things (not fully) in rewireChain
// v0.4.6.2 modified rewireChain to act on chainList
// v0.4.6.1 fix List.new (but still not working)
// v0.4.6 move to immutable chainIn and chainOut that remain connected to the outside world
// v0.4.5 added getters for chainName, chainNameSym and numChannels
// v0.4.4 added insert and rewrirteChain (not yet fully tested)
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

	var < chainName;
	var < chainNameSym;
	var chainInSym;
	var chainOutSym;
	var < numChannels;
	var < chainList; // this will be a list of the Ndef symbols in the chain in order

	*initClass {
		var text;
		version = "v0.4.6.9";
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

		// Entry point: receives external signal
		postln("DEBUG--- chainNameSym is: " ++ chainNameSym);

		chainInSym = (chainName ++ "In").asSymbol;
		postln("DEBUG--- Ndef name should be " ++ chainInSym);

		Ndef(chainInSym.asSymbol).reshaping_(\elastic).source = {
			\in.ar(0 ! numChannels)   // instance width, not a hard-coded 6
		};
		// Chain output: goes to external world
		postln("DEBUG--- chainNameSym is: " ++ chainNameSym);

		chainOutSym = (chainName ++ "Out").asSymbol;
		postln("DEBUG--- Ndef name should be " ++ chainOutSym);

		Ndef(chainOutSym.asSymbol).reshaping_(\elastic).source = {
			\in.ar(0 ! numChannels)   // instance width, not a hard-coded 6
		};

		// console report:
		("NChain init: name=" ++ chainName
			++ " sink=" ++ chainNameSym
			++ " channels=" ++ numChannels).postln;

		// CONNECT THEM FOR FIRST
		this.rewireChain;
		^this
	}

	// getters:

	getChainName     { ^chainName }

	getChainNameSym  { ^chainNameSym }

	getNumChannels   { ^numChannels }


	// We need this because since we're rewiring the chain in full, we need to keep what was coming into the chain connected.
	connectSource { |sourceSym|
		var firstIntoChain;
		if (chainList.notNil and: { chainList.notEmpty }) {
			firstIntoChain = chainList[0];
			Ndef(firstIntoChain) <<> Ndef(sourceSym);
			("NChain connectSource: " ++ sourceSym ++ " -> " ++ firstIntoChain).postln;
		};
		^this
	}

	makePassthrough { |name = "defaultChain"|
		Ndef(name.asSymbol).reshaping_(\elastic).source = {
			// Read the audio input named \in with an explicit width.
			// Pick a width that covers your expected max (e.g., 6 for hex).
			\in.ar(0 ! numChannels)   // returns silent zeros on channels with no signal
		};
		^this
	}

	rewireChain {
		// CLARITY: It probably makes the most sense to copy the list into a new one, insert the out and in at the beginning and end, and connect everyone
		var fullchainList = List.new;

		postln("rewireChain: chainList = " ++ chainList.asString);

		fullchainList = [chainName ++ "Out"] ++ chainList ++ [chainName ++ "In"];
		postln("rewireChain: fullchainList = " ++ fullchainList.asString);

		// connect the middle bits:
		//postln("DEBUG---: chainList = " ++ chainList.asString);
		fullchainList.doAdjacentPairs { |left, right|
			postln("DEBUG---: left = " ++ left ++ " right = " ++ right);
			Ndef(left.asSymbol) <<> Ndef(right.asSymbol);
		};

		//postln("DEBUG---: rewireChain complete.");
		//postln("DEBUG---: this.printChain: ");
		this.printChain;
		^this;
	}

	insert { | argName |
		var newName, newSymbol, insertIndex, alreadyPresent;

		newName = chainName ++ argName.asString;
		newSymbol = newName.asSymbol;

		if (chainList.isNil or: { chainList.isEmpty }) {
			chainList = List.new;
		};

		alreadyPresent = chainList.includes(newSymbol);
		if (alreadyPresent) {
			("NChain insert: '" ++ newSymbol ++ "' is already in the chain; skipping").postln;
			^this;
		};

		this.makePassthrough(newName);

		insertIndex = 0;
		chainList = chainList.copy.insert(insertIndex, newSymbol);

		this.rewireChain;

		("NChain insert: added " ++ newSymbol).postln;
		^this;
	}

	insertTest { |argName|
		var newName, newSymbol, insertIndex, alreadyPresent;

		newName = chainName ++ argName.asString;
		newSymbol = newName.asSymbol;

		if (chainList.isNil or: { chainList.isEmpty }) {
			chainList = List.new;
		};

		alreadyPresent = chainList.includes(newSymbol);
		if (alreadyPresent) {
			("NChain insertTest: '" ++ newSymbol ++ "' is already in the chain; skipping").postln;
			^this;
		};

		// Define the stage as a passthrough that halves amplitude (≈ -6 dB)
		Ndef(newSymbol).reshaping_(\elastic).source = {
			var sig;
			sig = \in.ar(0 ! numChannels);
			sig * 0.5
		};

		insertIndex = 0; // insert at the head of the internal chain
		chainList = chainList.copy.insert(insertIndex, newSymbol);

		this.rewireChain;

		("NChain insertTest: added " ++ newSymbol ++ " with -6 dB passthrough").postln;
		^this;
	}

	remove {
		// this would disconnect the last Ndef in the chain and (possibly) free (clear?) it.

		// (1) connect penultimate to chainname
		// (2) free last Ndef
		^this
	}

    removeNewest {
        var removedSym, newList;

        // 1) Nothing to remove?
        if (chainList.isNil or: { chainList.isEmpty }) {
            ("NChain removeNewest: chain '" ++ chainName ++ "' has no stages; nothing to remove.").postln;
            ^this;
        };

        // 2) We insert at head (index 0), so the newest is at index 0.
        removedSym = chainList[0];

        // 3) Make a real copy, mutate the copy, then reassign.
        newList = chainList.copy;
        newList.removeAt(0);    // remove from head; returns the removed element (ignored)
        chainList = newList;    // keep chainList a List

        // 4) Rewire, then clear the removed Ndef.
        this.rewireChain;
        Ndef(removedSym).clear;

        ("NChain removeNewest: removed " ++ removedSym ++ " (most recent).").postln;
        ^this;
    }
    // removeNewest {
    //     var removedSym, newList;

    //     if (chainList.isNil or: { chainList.isEmpty }) {
    //         ("NChain removeNewest: chain '" ++ chainName ++ "' has no stages; nothing to remove.").postln;
    //         ^this;
    //     };

    //     removedSym = chainList[0];
    //     newList = chainList.copy.removeAt(0);
    //     chainList = newList;

    //     this.rewireChain;
    //     Ndef(removedSym).clear;

    //     ("NChain removeNewest: removed " ++ removedSym ++ " (most recent).").postln;
    //     ^this;
    // }

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


	getChainList {
		// returns a list
		^(chainList.isNil.if({ List.new }, { chainList.copy }))
	}

	getChainAsArrayOfSymbols {
		// return as an Array of Symbols
		^(chainList.isNil.if({ #[] }, { chainList.asArray }))
	}


}