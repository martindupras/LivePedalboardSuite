// NChain.sc

// v0.4.7.2 add insertAt method - works!
// v0.4.7.1 add removeAt method - works!
// v0.4.7.0 added remove method that calls removeNewest
// v0.4.6.9 add removeNewest method - works!
// v0.4.6.8 remove commented out and tidy
// ...

// MD 20251013 (Older header comments deleted - version history on GH)

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
		version = "v0.4.7.2";
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

    insertAt { |argName, index|
        var newName, newSymbol, size, insertIndex, alreadyPresent, newList;

        // Ensure we have a list to work with
        if (chainList.isNil) {
            chainList = List.new;
        };

        // Index must be an Integer
        if (index.isKindOf(Integer).not) {
            ("NChain insertAt: index must be an Integer (got: " ++ index.class.name ++ ").").postln;
            ^this;
        };

        // Compose per-chain unique symbol (e.g., "chaintestalpha" -> \chaintestalpha)
        newName = chainName ++ argName.asString;
        newSymbol = newName.asSymbol;

        // Avoid duplicates
        alreadyPresent = chainList.includes(newSymbol);
        if (alreadyPresent) {
            ("NChain insertAt: '" ++ newSymbol ++ "' is already in the chain; skipping").postln;
            ^this;
        };

        // Clamp index to valid insertion range [0, size]
        size = chainList.size;
        insertIndex = index.clip(0, size);
        if (insertIndex != index) {
            ("NChain insertAt: clamped index " ++ index ++ " -> " ++ insertIndex
                ++ " (valid range 0.." ++ size ++ ")").postln;
        };

        // Define the stage as a passthrough (elastic width)
        this.makePassthrough(newName);

        // Insert at position and commit
        newList = chainList.copy;
        newList.insert(insertIndex, newSymbol);
        chainList = newList;

        // Rewire and report
        this.rewireChain;
        ("NChain insertAt: added " ++ newSymbol ++ " at index " ++ insertIndex).postln;
        ^this;
    }

    insertTestAt { |argName, index|
        var newName, newSymbol, size, insertIndex, alreadyPresent, newList;

        // Ensure we have a list
        if (chainList.isNil) {
            chainList = List.new;
        };

        // Index must be an Integer
        if (index.isKindOf(Integer).not) {
            ("NChain insertTestAt: index must be an Integer (got: " ++ index.class.name ++ ").").postln;
            ^this;
        };

        // Compose per-chain unique symbol (e.g., "chaintestalpha" -> \chaintestalpha)
        newName = chainName ++ argName.asString;
        newSymbol = newName.asSymbol;

        // Avoid duplicates
        alreadyPresent = chainList.includes(newSymbol);
        if (alreadyPresent) {
            ("NChain insertTestAt: '" ++ newSymbol ++ "' is already in the chain; skipping").postln;
            ^this;
        };

        // Clamp index to valid insertion range [0, size]
        size = chainList.size;
        insertIndex = index.clip(0, size);
        if (insertIndex != index) {
            ("NChain insertTestAt: clamped index " ++ index ++ " -> " ++ insertIndex
                ++ " (valid range 0.." ++ size ++ ")").postln;
        };

        // Define the stage as a passthrough that halves amplitude (≈ -6 dB)
        Ndef(newSymbol).reshaping_(\elastic).source = {
            var sig;
            sig = \in.ar(0 ! numChannels);
            sig * 0.5
        };

        // Insert at position and commit
        newList = chainList.copy;
        newList.insert(insertIndex, newSymbol);
        chainList = newList;

        // Rewire and report
        this.rewireChain;
        ("NChain insertTestAt: added " ++ newSymbol ++ " at index " ++ insertIndex ++ " with -6 dB passthrough").postln;
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
        this.removeNewest;
        ^this
	}


    removeAt { |index|
        var size, removedSym, newList;

        // Guard: empty or undefined list
        if (chainList.isNil or: { chainList.isEmpty }) {
            ("NChain removeAt: chain '" ++ chainName ++ "' has no stages; nothing to remove.").postln;
            ^this;
        };

        // Guard: index must be an Integer within range
        if (index.isKindOf(Integer).not) {
            ("NChain removeAt: index must be an Integer (got: " ++ index.class.name ++ ").").postln;
            ^this;
        };

        size = chainList.size;
        if ((index < 0) or: { index >= size }) {
            ("NChain removeAt: index " ++ index ++ " out of range 0.." ++ (size - 1)).postln;
            ^this;
        };

        // Remove the selected stage from a copy, then commit
        newList = chainList.copy;
        removedSym = newList.removeAt(index);   // returns the removed element
        chainList = newList;

        // Rewire the chain without that stage, then clear the Ndef for the removed stage
        this.rewireChain;
        if (removedSym.isKindOf(Symbol)) {
            Ndef(removedSym).clear;
        };

        ("NChain removeAt: removed " ++ removedSym ++ " at index " ++ index).postln;
        ^this;
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