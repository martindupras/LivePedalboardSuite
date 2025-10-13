// NChain.sc

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
		version = "v0.4.6.6";
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


		// Ndef(chainNameSym).reshaping_(\elastic).source = {
		// 	\in.ar(0 ! numChannels)   // instance width, not a hard-coded 6
		// };
		// and add it to the chainList
		// chainList.add(chainNameSym); // add the name of the chain to the list

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




// REMOVED FOR NOW
// 	insert  { |argName|
//         var newName,newSymbol, sinkIndex, insertIndex, alreadyPresent;
// 		// This will create a new Ndef and add it in the right place. We will need to keep track of what is conencted so that anything that was connected to chainName goes into the new thing and the new thing gets connected to the chain.

// 		newName = chainName ++ argName.asString; // keep everything as string for now
// 		newSymbol = newName.asSymbol;
//         sinkIndex; // should always be 0, first in list (Ndef direction)
//         insertIndex; // should be 1, second in list (Ndef direction) (we can eventually do insertAt with index argument)
//         alreadyPresent; // flag to avoid duplicates

// 		// we may have an instance variable that is keeping the name of the last Ndef; nil if there isn't one

// 		// if no effect (just insert passthrough):
// 		// this.makePassthrough(newName);
// 		// (1) connect existing to this one -- HOW DO WE FIND OUT?

// 		// (2) connect this one to chainName
// 		// Ndef(\chainName).source = { Ndef(newName.asSymbol).ar }; // something like this
// 		//


// /////// checks --- REVIEW if needed and correct
//     // Ensure sink exists and is at chainList[0] as invariant
//     // if (chainList.isNil or: { chainList.isEmpty }) {
//     //     chainList = List.new;
//     // } {
//     //     // If somehow sink isn't present, ensure it is (as first)
//     //     if (chainList.includes(chainNameSym).not) {
//     //         chainList.addFirst(chainNameSym);
//     //     } {
//     //         // If sink is not first, move it to first to preserve invariant
//     //         sinkIndex = chainList.indexOf(chainNameSym);
//     //         if (sinkIndex != 0) {
//     //             chainList.removeAt(sinkIndex);
//     //             chainList.addFirst(chainNameSym);
//     //         };
//     //     };
//     // };

    
// if (chainList.isNil or: { chainList.isEmpty }) {
//     chainList = List.new;
// };
// ///////
//         // check if already present. For now skip; EVENTUALLY add 1,2,3 to the name (e.g. we may want two delays)
//         alreadyPresent = chainList.includes(newSymbol);
//         if (alreadyPresent) {
//             ("NChain insert: '" ++ newSymbol ++ "' is already in the chain; skipping").postln;
//             ^this
//         };

//        /* DEBUGGING -- working now.
//         ("inside add method of NChain " ++ chainName).postln;
//         postln("string: " + newName);
//         postln("symbol" + newSymbol);
//         */
       
       
//         // this.rewireChain;
//         // ("NChain insert: added " ++ newSymbol ++ " before sink " ++ chainNameSym).postln;


//         // Insert immediately upstream of the sink (index 1)
//         insertIndex = 1;
//         chainList = chainList.copy.insert(insertIndex, newSymbol); // insert into the list at index 1, right after sink

//         // Now rewire the full chain
//         this.rewireChain;

//         // Report
//         ("NChain insert: added " ++ newSymbol ++ " before sink " ++ chainNameSym).postln;

// 		^this
// 	}

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

    
	getChainList {
        // returns a list
		^(chainList.isNil.if({ List.new }, { chainList.copy }))
	}

    getChainAsArrayOfSymbols {
        // return as an Array of Symbols
        ^(chainList.isNil.if({ #[] }, { chainList.asArray }))
    }

    /*

    // Rewire the entire chain according to chainList (sink … source)
rewireChain {
    var names, i, leftName, rightName;

    if (chainList.isNil or: { chainList.size < 2 }) { ^this };

    names = chainList.asArray;

    i = 0;
    while { i < (names.size - 1) } {
        leftName  = names[i];       // downstream (consumer) on the left
        rightName = names[i + 1];   // upstream (producer) on the right
        Ndef(leftName) <<> Ndef(rightName);
        i = i + 1;
    };

    this.printChain;    // optional: show the current chain after rewiring
    ^this
}

// Define/replace a passthrough Ndef with this instance's channel count
makePassthroughFor { |nameSym|
    var sym;
    sym = nameSym.asSymbol;
    Ndef(sym).reshaping_(\elastic).source = {
        \in.ar(0 ! numChannels)  // instance width, explicit and elastic
    };
    ^this
}

// Insert a node immediately upstream of the sink (at index 1), then rewire
insert { |argName|
    var newSymbol, sinkIndex, insertIndex, alreadyPresent;

    // Compose a unique per-chain symbol (e.g., "myChainalpha" -> \myChainalpha)
    newSymbol = (chainName ++ argName.asString).asSymbol;

    // Ensure sink exists and is at chainList[0] as invariant
    if (chainList.isNil or: { chainList.isEmpty }) {
        chainList = List[chainNameSym];
    } {
        // If somehow sink isn't present, ensure it is (as first)
        if (chainList.includes(chainNameSym).not) {
            chainList.addFirst(chainNameSym);
        } {
            // If sink is not first, move it to first to preserve invariant
            sinkIndex = chainList.indexOf(chainNameSym);
            if (sinkIndex != 0) {
                chainList.removeAt(sinkIndex);
                chainList.addFirst(chainNameSym);
            };
        };
    };

    // Avoid duplicates
    alreadyPresent = chainList.includes(newSymbol);
    if (alreadyPresent) {
        ("NChain insert: '" ++ newSymbol ++ "' is already in the chain; skipping").postln;
        ^this
    };

    // Create the node as a passthrough by default (safe identity stage)
    this.makePassthroughFor(newSymbol);

    // Insert immediately upstream of the sink (index 1)
    insertIndex = 1;
    chainList = chainList.copy.insert(insertIndex, newSymbol);

    // Rewire the full chain and report
    this.rewireChain;
    ("NChain insert: added " ++ newSymbol ++ " before sink " ++ chainNameSym).postln;

    ^this
}

    */
}