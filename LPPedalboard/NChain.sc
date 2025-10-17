// NChain.sc

// v0.4.7.9 move to use ndefMaker
// v0.4.7.8 adding makeAnNdef method and calling it from insert -- not sure it's working, need troublshooting
// v0.4.7.7 renamed insertTest to insertPassthrough and insertTestAt to insertPassthroughAt; compatibility methods added
// v0.4.7.7 print chainList to LPDisplay from NChain.init -- working
// v0.4.7.6 make rewireChain post test message to LPDisplay
// v0.4.7.5 add logger var and check method
// v0.4.7.4 added comments and little formatting tidy
// v0.4.7.3 added planning notes before init method.
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

	// added for v0.4.7.5
	var logger; 

	var < chainName;
	var < chainNameSym;
	var chainInSym;
	var chainOutSym;
	var < numChannels;
	var < chainList; // this will be a list of the Ndef symbols in the chain in order

	var <> display;
	var <  procLib;
	var <  ndefMaker; // added v0.4.7.9

	*initClass {
		var text;
		version = "v0.4.7.9";
		defaultNumChannels = 2; // Set a sensible default

		text = "Nchains " ++ version;
		text.postln;
	}

	*new  { |name, argDisplay, argProcLib| ^super.new.init(name, argDisplay, argProcLib) }

    // REVIEW: work out what we need in init to make display and procLib work 
    // here. display could default to nil because we could conceivably have a chain
    // that doesn't need to display (e.g. we could have a chain within a chain);
    // procLib could in the absence of an argument default to LPProcessorLibrary
    // and load it up here with no argument reference. Consider my options.

	init { |name = "defaultChain" , argDisplay = nil, argNdefMaker |

		logger = MDMiniLogger.new();

		//<DEBUG> 
		postln("***** NChain.init *****");
		postln(">>> NChain init: argDisplay = " ++ argDisplay.asString);
		postln(">>> NChain init: argProcLib = " ++ argProcLib.asString);
		//</DEBUG>

		chainName = name.asString; // store the name as String
		chainNameSym = chainName.asSymbol; // and as Symbol... possibly not needed. Belt and braces.

		display = argDisplay; 
		//<DEBUG>
		// working in v0.4.7.7
		//display.sendPaneText(\left, "REACHED from NChain.init");
		//</DEBUG>

		procLib = argProcLib; // DEPREACATE in favour of ndefMaker
		ndefMaker = argNdefMaker; // added v0.4.7.9

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

		// Connect on init
		this.rewireChain;
		^this
	}

	// getters:

	getChainName     { ^chainName }

	getChainNameSym  { ^chainNameSym }

	getNumChannels   { ^numChannels }


// v0.4.7.3 I don't think we need this method any longer
	connectSource { |sourceSym|
		var firstIntoChain;
		if (chainList.notNil and: { chainList.notEmpty }) {
			firstIntoChain = chainList[0];
			Ndef(firstIntoChain) <<> Ndef(sourceSym);
			("NChain connectSource: " ++ sourceSym ++ " -> " ++ firstIntoChain).postln;
		};
		^this
	}

    // used to make a passthrough Ndef
	makePassthrough { |name = "defaultChain"|
		Ndef(name.asSymbol).reshaping_(\elastic).source = {
			// Read the audio input named \in with an explicit width.
			// Pick a width that covers your expected max (e.g., 6 for hex).
			\in.ar(0 ! numChannels)   // returns silent zeros on channels with no signal
		};
		^this
	}
	
	    // used to make an Ndef in the chain using the defintion gathered in procLib

		// At the minim we want to pass the key, seek the process in the lib, and if found make an Ndef. Put defensive cdoding once that's working (e.g. no key of that name)


	// REVIEW NOW; we don't need to use this method if we're using ndefMaker
	makeAnNdef { |name, key |
		var func;
		// look up the function in the procLib
		//func = procLib.get(key.asSymbol);
		//func = procLib.get(key.asSymbol);

		Ndef(name.asSymbol).reshaping_(\elastic).source = func;

		^this
	}

	rewireChain {
		// CLARITY: It probably makes the most sense to copy the list into a new one, insert the out and in at the beginning and end, and connect everyone
		
        // create the list we'll use (starts empty)
        var fullchainList = List.new;

        //DEBUG
		postln("rewireChain: chainList = " ++ chainList.asString);


        // new list chainNameOut, chainList[0], chainList[1], ..., chainList[n], chainNameIn
		fullchainList = [chainName ++ "Out"] ++ chainList ++ [chainName ++ "In"];
		
        //DEBUG
        postln("rewireChain: fullchainList = " ++ fullchainList.asString);

		// Connect Ndefs as per list (n <<> n+1))
		//postln("DEBUG---: chainList = " ++ chainList.asString);
		fullchainList.doAdjacentPairs { |left, right|
			postln("DEBUG---: left = " ++ left ++ " right = " ++ right);
			Ndef(left.asSymbol) <<> Ndef(right.asSymbol); // could be rewritten .set(\in, right) -- might be clearer to someone unfamiliar with the (unsearchable) <<> operator
		};

		//postln("DEBUG---: rewireChain complete.");
		//postln("DEBUG---: this.printChain: ");

		// working from v0.4.7.6
		// REVIEW: for now only print the mutable chainList, not the fullchainList
		display.sendPaneText(\left,chainList.asString);

		// rework to list line by line:
		display.sendPaneText(
			\left,
			chainList.collect({ |sym| sym.asString }).join(Char.nl)
			); //split with newline characters; working now. Coudl be put in a separate method if needed. 

		this.printChain;
		^this;
	}

	// QUESTION HERE:
	// previously we're doing 	
	//insert { | argName | ...
	//
	// what we have to do here is request the processor that we want (key in ndefMaker) 
	// and return a unique name for the Ndef which we need to store in chainList


	insert { | argName | // string or symbol?
		var newName, newSymbol, insertIndex, alreadyPresent;
		vasr receivedNdefName; // added v0.4.7.9
		
		// trying in v0.4.7.8
		var functionToInsert; // we will make this the function found in procLib
		
		functionToInsert = procLib.get(argName.asSymbol); // seems to work
		
		if (functionToInsert.isNil) {
			("NChain insert: no processor function named '" ++ argName ++ "' found in library; skipping").postln;
			^this;
		};	

		postln("NChain insert: got function from library for '" ++ argName ++ "'");
		// end trying in v0.4.7.8

		newName = chainName ++ argName.asString;
		//newSymbol = newName.asSymbol;

		if (chainList.isNil or: { chainList.isEmpty }) {
			chainList = List.new;
		};

        // EVENTUALLY: if already present, make a new one but append a number to make it unique
        // do the same for insertAt and insertTestAt
		alreadyPresent = chainList.includes(newSymbol);
		if (alreadyPresent) {
			("NChain insert: '" ++ newSymbol ++ "' is already in the chain; skipping").postln;
			^this;
		};

		// REPLACE THIS
		//this.makePassthrough(newName);


		// OLD WAY
		//this.makeAnNdef(newSymbol,newName.asSymbol); // make the Ndef using the function from the library
		receivedNdefName = ndefMaker.create(argName.asSymbol, newSymbol); // returns actual name of Ndef created

		insertIndex = 0;
		// chainList = chainList.copy.insert(insertIndex, newSymbol);
		chainList = chainList.copy.insert(insertIndex, receivedNdefName);

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
		insertPassthroughAt(argName, index);
	}

    insertPassthroughAt { |argName, index|
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

	// compatibility 
	insertTest { |argName|
		this.insertPassthrough(argName);
	}

	insertPassthrough { |argName|
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

	printChain{
		// this method should print out what Ndefs make up the chain printed to the console
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

	 check {
        logger.info("This is NChain; check.");
    }

}