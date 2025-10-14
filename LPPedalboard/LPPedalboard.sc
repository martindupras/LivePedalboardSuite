// LPPedalboard.

// v1.0.9 added display and processorlib args to NChain.new in setupStaticNdefs
// v1.0.8 removed old commented out code; probably not needed; can be recovered from previous commits.
// v1.0.7 got init working with setupStaticNdefs finally.
// v1.0.6 added ensureServerReady method and call it at top of setupStaticNdefs -- but not solving the issue.
// v1.0.5 add setupStaticNdefs to init; add logger var
// v1.0.4 First attempt at creating pedalboardIn & pedalboardOut NDefs, connecting them to NChain, and putting metering in pedalboardOut.
// v1.0.3 review code, add comments
// v1.0.2 added setupStaticNdefs method to create pedalboardIn, pedalboardOut, and theNChain
// v1.0.1 added some comments describing new strategy using NChain class

/* This class manages the pedalboard operations:
- sets up  input (pedalboardIn) and output (pedalboardOut) Ndefs (immmutable)
- connect an Nchain between them so that we should have:
   pedalboardOut <<> theNChainOut||theNChainIn  <<> pedalboardIn

   pedalboardOut pass through AND do the amplitude measurements for metering (\SendPeakRMSA)
   
   The orchestrator (LPOchestrator should be receiving the commands from the commandManager). 
   Those commands should be queuedd up and sent to a method that makes them happen when we 
   receive a "activate" (or "execute" or whatever -- used to be "switch" because originally 
   we would switch between chainA and chainB.) [Note: we have an opportunity to schedule those
   chains actions at specific time in the future,e.g. on next beat or next bar; implement those
   when we have some tempo/beats mechanism.)]

   QUESTION FOR SH: NChain sends to display, or to here first? 
This class should also handle the passing of display information about the WHOLE pedalboard and 
the state of things (e.g. command queued, or effect is bypassed, etc.) NChain PROBABLY should not
be displaying things directly to the LPDisplay. 

TODO:
// test existing; right now init works and we have sound audible

- display something from pedalboard to display
- do insertion and removal to theChain from pedalboard
- .play and .stop on pedalboardOut; make a help method, display state in LPDisplay
- figure out insertion of processorLib definition into a slot in the NChain
- add .help and .api methods (not sure when best while this is changing, but handy)
- make console messages a little easier to read -- too many right now. Use local 
    incr/decr of verbosity class? or put in conditional with flags?
- really really basic command arrival from commandManager to pedalboard; 
doesn't have to be from tree right now

*/

LPPedalboard : Object {

    classvar < version; // so that we can print to console on init

    // added for v1.0.5
    var logger; 

    // REVIEW THESE:
    var < currentChain; // POSSIBLY OBSOLETE
    var < nextChain; // POSSIBLY OBSOLETE
    // QUESTION: is there an advantage to keeping the list here? We can always get it from NChain.
    var chainAList; 
    var chainBList; // POSSIBLY OBSOLETE

    // REVIEW: is there any point in keeping the bypass states in here? 
    // They will be held in processors eventually (give some thought)
    var bypassA; // IdentityDictionary: key(Symbol) -> Bool
    var bypassB; // IdentityDictionary: key(Symbol) -> Bool

    // KEEP THESE:
    var < defaultNumChannels; // QUESTION: do I need a default here?
    var < numChannels; 
    var < defaultSource;
    var < display; // LPDisplay
    var < processorLib; // LPProcessorLibrary
    var < ready; 

    // new for v1.0.2
    var < theNChain;
    var pedalboardInSym = \pedalboardIn;
	var pedalboardOutSym = \pedalboardOut;

    *initClass {
        var text;
        version = "v1.0.9";
        text = "LPPedalboard " ++ version;
        text.postln;
    }
    *new { arg disp = nil, aProcessorLib;
        ^super.new.init(disp, );
    }

/* 
--- 20251013-1924:new plan description: ---> moved to bottom of this file for tidiness <---
*/
    init { arg argDisp, argProcessorLib;

        var testSourceNdefSym; // FOR SANITY CHECKS

        var sinkFunc; // OBSOLETE

        logger = MDMiniLogger.new();
        display = argDisp;  // KEEP
		processorLib = argProcessorLib; // KEEP
        numChannels = 2; // eventually hex // possibly inherit from defaultNumChannels?

        //TODO: Decide what we do here... we need a test source. Do we have a makeTestSource method or some such
        defaultSource = \ts0; // silence as source

//// <sanity checks>
        //make a source Ndef
        testSourceNdefSym = \pulseNoise01; // don't use, just remind me
        Ndef(\pulseNoise01, {SinOsc.ar(freq:3, mul: { PinkNoise.ar(0.1!2)})}); 

//// </sanity checks>

        // OBSOLETE: if needed use makepassthrough from NChains.sc
        sinkFunc = {
            var inputSignal;
            inputSignal = \in.ar(defaultNumChannels);
            inputSignal
        };

        // set up initial chains
        this.setupStaticNdefs;

        // Now plug test source into the pedalboard:
        Ndef(pedalboardInSym.asSymbol) <<> Ndef(testSourceNdefSym);

        if(display.notNil) {
            display.sendPaneText(\left, currentChain.asString);
			display.sendPaneText(\right,nextChain.asString);
        };

        ^this
    }

    setupStaticNdefs {

         logger.info("setupStaticNdefs called");
        // here create the pedalboardIn and pedalboardOut Ndefs and instantiate theNChain

        this.ensureServerReady;
        logger.info("*** ensureServerReady called ***");

		Ndef(pedalboardInSym.asSymbol).reshaping_(\elastic).source = {\in.ar(0 ! numChannels)   };
		Ndef(pedalboardOutSym.asSymbol).reshaping_(\elastic).source = { \in.ar(0 ! numChannels)  };
        
        logger.info("Created pedalboardIn and pedalboardOut Ndefs");

        // REVIEW: first argument is the name of the chain itself; adapt 
        //NChain class to also accept arguments argDisplay (for LPDisplay)
        // and argProcLib (for LPProcessorLibrary)

        //theNChain = NChain.new(\pedalboardChainA);
        theNChain = NChain.new(\pedalboardChainA, display, processorLib);
    

        logger.info("Created theNChain NChain instance with display and processorlib args");

        // connect them all 
        Ndef(pedalboardOutSym.asSymbol) <<> Ndef(\pedalboardChainAOut);
        Ndef(\pedalboardChainAIn) <<> Ndef(pedalboardInSym.asSymbol);

        // Now make end of pedalboard audible
        Ndef(pedalboardOutSym.asSymbol).play;
        logger.info("Pedalboard should be audible... is it? line 254).");

        ^this
    }

    initChainTest {

		// Unconditional test sources
		Ndef(\testmelodyA, {
			var t, e, f, sig;
			t = Impulse.kr(2.2);
			e = Decay2.kr(t, 0.01, 0.30);
			f = Demand.kr(t, 0, Dseq([220, 277.18, 329.63, 392], inf));
			sig = SinOsc.ar(f) * e * 0.22;
			sig ! 2
		});
		Ndef(\testmelodyB, {
			var t, e, f, sig;
			t = Impulse.kr(3.1);
			e = Decay2.kr(t, 0.02, 0.18);
			f = Demand.kr(t, 0, Dseq([392, 329.63, 246.94, 220, 246.94], inf));
			sig = Pulse.ar(f, 0.35) * e * 0.20;
			sig ! 2
		});
		Ndef(\srcBleeps, {
			var trig, freq, env, tone, sig;
			trig = Dust.kr(3);
			freq = TExpRand.kr(180, 2800, trig);
			env  = Decay2.kr(trig, 0.005, 0.20);
			tone = SinOsc.ar(freq + TRand.kr(-6, 6, trig));
			sig  = RLPF.ar(tone, (freq * 2).clip(80, 9000), 0.25) * env;
			Pan2.ar(sig, LFNoise1.kr(0.3).range(-0.6, 0.6)) * 0.2
		});
		Ndef(\srcPulsedNoise7, {
			WhiteNoise.ar(1!2) * SinOsc.kr(7).range(0,1) * 0.2
		});

				Ndef(\chainA, {
					var x;
					x = \in.ar(0!2);
					SendPeakRMS.kr(x, 24, 3, '/peakrmsA', 2001);
					x
				}).ar(2);

				Ndef(\chainB, {
					var y;
					y = \in.ar(0!2);
					SendPeakRMS.kr(y, 24, 3, '/peakrmsB', 2002);
					y
				}).ar(2);


		Ndef(\chainA)<<>Ndef(\testmelodyA);
		Ndef(\chainB)<<>Ndef(\testmelodyB);

		postln('initChainTest done');

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

    // ───────────────────────────────────────────────────────────────
    // public API
    // ───────────────────────────────────────────────────────────────
    // add a setter (public)
    setProcessorLib { arg lib;
        processorLib = lib;
    }
    setDisplay { arg disp;
        var shouldShow;
        display = disp;
        shouldShow = display.notNil;
        if(shouldShow) {
            display.showInit(this, version, currentChain, nextChain);
        };
    }

    // NEEDS REVISION ->
    help {
        var text;
        text = String.new;
        text = text
        ++ "MagicPedalboard " ++ version ++ "\n"
        ++ "Chains are Arrays of Symbols ordered [sink, …, source].\n"
        ++ "On init, creates \\chainA and \\chainB and plays CURRENT.\n\n"
        ++ "Core methods (operate mostly on the *next* chain):\n"
        ++ " printChains\n"
        ++ " playCurrent, stopCurrent, switchChain([fadeTime])\n"
        ++ " add(key), addAt(key, index)\n"
        ++ " removeAt(index), swap(indexA, indexB)\n"
        ++ " bypass(key, state=true), bypassAt(index, state=true)\n"
        ++ " clearChain\n"
        ++ "Current-chain bypass helpers:\n"
        ++ " bypassCurrent(key, state=true), bypassAtCurrent(index, state=true)\n"
        ++ "Diagnostics/helpers:\n"
        ++ " effectiveCurrent, effectiveNext, bypassKeysCurrent, bypassKeysNext, reset\n"
        ++ "Source setters:\n"
        ++ " setSource(key) [next], setSourceCurrent(key) [current]\n";
        text.postln;
    }

    // NEEDS REVISION:
    // should get a list from NChains.getChainAsList (or whatever) and copy in new list 
    // out, [contents of NChain], in 
    // because that's what we want to display in LPDisplayer

    printChains {
        var bypassAKeys, bypassBKeys, effectiveA, effectiveB, hasDisplay;
        var headerFunc, formatOne;
        bypassAKeys = this.bypassKeysForListInternal(chainAList);
        bypassBKeys = this.bypassKeysForListInternal(chainBList);
        effectiveA = this.effectiveListForInternal(chainAList);
        effectiveB = this.effectiveListForInternal(chainBList);
        hasDisplay = display.notNil and: { display.respondsTo(\showChainsDetailed) };
        if(hasDisplay) {
            display.showChainsDetailed(
                chainAList, chainBList,
                bypassAKeys, bypassBKeys,
                effectiveA, effectiveB
            );
        }{
            headerFunc = { arg titleString;
                var lineText;
                lineText = "==== " ++ titleString ++ " ====";
                lineText.postln;
            };
            formatOne = { arg titleString, listRef, bypassKeys, effectiveList;
                var sinkKey, sourceKey, lastIndex, indexCounter, processorsList, lineText, isBypassed, markText;
                lastIndex = listRef.size - 1;
                sinkKey = listRef[0];
                sourceKey = listRef[lastIndex];
                headerFunc.(titleString);
                ("src : " ++ sourceKey).postln;
                if(listRef.size > 2) {
                    "procs:".postln;
                    processorsList = listRef.copyRange(1, lastIndex - 1);
                    indexCounter = 1;
                    processorsList.do({ arg procKey;
                        isBypassed = bypassKeys.includes(procKey);
                        markText = if(isBypassed) { "BYP" } { "ON " };
                        lineText = " [" ++ indexCounter ++ "] " ++ procKey ++ " (" ++ markText ++ ")";
                        lineText.postln;
                        indexCounter = indexCounter + 1;
                    });
                }{
                    "procs: (none)".postln;
                };
                ("sink: " ++ sinkKey).postln;
                ("eff : " ++ effectiveList.join(" -> ")).postln;
                "".postln;
            };
            formatOne.("CURRENT", chainAList, bypassAKeys, effectiveA);
            formatOne.("NEXT", chainBList, bypassBKeys, effectiveB);
        };
    }

    // NEEDS REVISION: what does that mean in the new approach?
    playCurrent {
        var sinkKey, canRun;
        sinkKey = currentChain[0];
        canRun = this.ensureServerTree;
        if(canRun.not) { ^this };
        this.rebuild(currentChain);
        Server.default.bind({
            Ndef(sinkKey).play(numChannels: defaultNumChannels);
        });
        if(display.notNil) {
            display.showPlay(sinkKey);
        };
        // enforce exclusive invariant (Option A) after play
        this.enforceExclusiveCurrentOptionA(0.1);
    }

    // NEEDS REVISION: what does that mean in the new approach?
    stopCurrent {
        var sinkKey, canRun;
        sinkKey = currentChain[0];
        canRun = this.ensureServerTree;
        if(canRun.not) { ^this };
        Server.default.bind({
            Ndef(sinkKey).stop;
        });
        if(display.notNil) {
            display.showStop(sinkKey);
        };
    }
    // NEEDS REVISION: what does that mean in the new approach?
    // We probably want something conceptually like "execute!" or "engage!" 
    // which makes effective what the chain is now; possibly instead
    // of switching to a different chain, we in effect make NChain invoke 
    // rewireChain on the "next" chain that we have played/constructed.

    switchChain { arg fadeTime = 0.1;
        var temporaryList, oldSinkKey, newSinkKey, actualFadeTime, canRun;
        canRun = this.ensureServerTree;
        if(canRun.not) { ^this };
        actualFadeTime = fadeTime.clip(0.08, 0.2);
        oldSinkKey = currentChain[0];
        newSinkKey = nextChain[0];
        Server.default.bind({
            // set fade durations
            Ndef(oldSinkKey).fadeTime_(actualFadeTime);
            Ndef(newSinkKey).fadeTime_(actualFadeTime);
            // prebuild NEXT so it is ready, then start it (will fade in)
            this.rebuildUnbound(nextChain);
            Ndef(newSinkKey).play(numChannels: defaultNumChannels);
            // stop OLD (will fade out)
            Ndef(oldSinkKey).stop;
            // swap pointers
            temporaryList = currentChain;
            currentChain = nextChain;
            nextChain = temporaryList;
            // ensure both chains are in correct post-swap state
            this.rebuildUnbound(currentChain);
            this.rebuildUnbound(nextChain);
        });
        // enforce exclusivity post-swap (CURRENT uses actualFadeTime, NEXT silenced)
        this.enforceExclusiveCurrentOptionA(actualFadeTime);
        if(display.notNil) {
            display.showSwitch(oldSinkKey, currentChain[0], currentChain, nextChain);
        };
    }
    // ─── next-chain mutations ─────────────────────────────────────
    
    // REVIEW: call the NChain one
    add { arg key;
        var insertIndex;
        insertIndex = nextChain.size - 1;
        this.addAt(key, insertIndex);
        if(display.notNil) { display.showMutation(\add, [key], nextChain) };
    }

    // REVIEW: call the NChain one
    addAt { arg key, index;
        var indexClamped, newList;
        indexClamped = index.clip(1, nextChain.size - 1);
        newList = nextChain.insert(indexClamped, key);
        this.setNextListInternal(newList);
        this.rebuild(nextChain);
        if(display.notNil) { display.showMutation(\addAt, [key, indexClamped], nextChain) };
    }

    // REVIEW: call the NChain one
    removeAt { arg index;
        var sizeNow, lastIndex, newList, removedKey;
        sizeNow = nextChain.size;
        lastIndex = sizeNow - 1;
        if(sizeNow <= 2) {
            if(display.notNil) { display.showError("removeAt refused: need at least [sink, source]") }
            { "refuse to remove: need at least [sink, source]".postln };
        }{
            if((index == 0) or: { index == lastIndex }) {
                if(display.notNil) { display.showError("removeAt refused: cannot remove sink or source") }
                { "refuse to remove sink or source".postln };
            }{
                removedKey = nextChain[index];
                newList = nextChain.copy;
                newList.removeAt(index);
                this.setNextListInternal(newList);
                this.bypassDictForListInternal(nextChain).removeAt(removedKey);
                this.rebuild(nextChain);
                if(display.notNil) { display.showMutation(\removeAt, [index, removedKey], nextChain) };
            };
        };
    }
    // REVIEW: if that exists, it probably should be a method in NChain
    swap { arg indexAParam, indexBParam;
        var lastIndex, indexA, indexB, newList, tempKey;
        lastIndex = nextChain.size - 1;
        indexA = indexAParam.clip(1, lastIndex - 1);
        indexB = indexBParam.clip(1, lastIndex - 1);
        if(indexA == indexB) {
            // nothing to do
        }{
            newList = nextChain.copy;
            tempKey = newList[indexA];
            newList[indexA] = newList[indexB];
            newList[indexB] = tempKey;
            this.setNextListInternal(newList);
            this.rebuild(nextChain);
            if(display.notNil) { display.showMutation(\swap, [indexA, indexB], nextChain) };
        };
    }

     // REVIEW: if that exists, it probably should be a method in NChain
    clearChain {
        var sinkKey, sourceKey, newList;
        if(nextChain.size < 2) { ^this };
        sinkKey = nextChain[0];
        sourceKey = nextChain[nextChain.size - 1];
        newList = [sinkKey, sourceKey];
        this.setNextListInternal(newList);
        this.bypassDictForListInternal(nextChain).clear;
        this.rebuild(nextChain);
        if(display.notNil) { display.showMutation(\clearChain, [], nextChain) };
    }
    // REVIEW DESIGN:
    // The most logical and guitarist-friendly approach is have a bypass parameter in 
    // ANY processor, and if we hit bypass anywhere we would access 
    // Ndef(theChain.getSlot(index)).set(\bypass, 1). Let's think this through 
    //because there should also be a method bypassSwitch, which sets 
    //state = !state. (pseudcode)

    bypass { arg key, state = true;
        var dict;
        dict = this.bypassDictForListInternal(nextChain);
        dict[key] = state;
        this.rebuild(nextChain);
        if(display.notNil) {
            display.showBypass(\next, key, state, nextChain, this.bypassKeysForListInternal(nextChain));
        };
    }
    bypassAt { arg index, state = true;
        var lastIndex, clampedIndex, keyAtIndex;
        lastIndex = nextChain.size - 1;
        clampedIndex = index.clip(1, lastIndex - 1);
        keyAtIndex = nextChain[clampedIndex];
        this.bypass(keyAtIndex, state);
    }
    // ─── current-chain bypass ─────────────────────────────────────
    bypassCurrent { arg key, state = true;
        var dict;
        dict = this.bypassDictForListInternal(currentChain);
        dict[key] = state;
        this.rebuild(currentChain);
        if(display.notNil) {
            display.showBypass(\current, key, state, currentChain, this.bypassKeysForListInternal(currentChain));
        };
    }
    bypassAtCurrent { arg index, state = true;
        var lastIndex, clampedIndex, keyAtIndex;
        lastIndex = currentChain.size - 1;
        clampedIndex = index.clip(1, lastIndex - 1);
        keyAtIndex = currentChain[clampedIndex];
        this.bypassCurrent(keyAtIndex, state);
    }
    // ─── source setters ───────────────────────────────────────────
    // KEEP
    setSource { arg key;
        var newList, lastIndex;
        lastIndex = nextChain.size - 1;
        newList = nextChain.copy;
        newList[lastIndex] = key;
        this.setNextListInternal(newList);
        this.rebuild(nextChain);
        if(display.notNil) { display.showMutation(\setSource, [key], nextChain) };
    }

    // REVIEW: what does this mean in the new approach?
    setSourceCurrent { arg key;
        var newList, lastIndex, isAList;
        lastIndex = currentChain.size - 1;
        newList = currentChain.copy;
        newList[lastIndex] = key;
        isAList = (currentChain === chainAList);
        if(isAList) { chainAList = newList; currentChain = chainAList } { chainBList = newList; currentChain = chainBList };
        this.rebuild(currentChain);
        if(display.notNil) { display.showMutation(\setSourceCurrent, [key], currentChain) };
    }
    // REVIEW: what does this mean in the new approach?
    setSourcesBoth { arg key;
        var k, lastA, lastB, curWasA, nextWasA, newA, newB, sizeOk;
        // pick a sensible key (today we want \testmelody)
        k = key ? \testmelody;
        // guard: require [sink, source] minimum on both chains
        sizeOk = (chainAList.size >= 2) and: { chainBList.size >= 2 };
        if(sizeOk.not) { ^this };
        // remember which concrete list object was CURRENT/NEXT *before* we replace them
        curWasA = (currentChain === chainAList);
        nextWasA = (nextChain === chainAList);
        // compute last indices
        lastA = chainAList.size - 1;
        lastB = chainBList.size - 1;
        // replace the *source symbol* (last position) on both lists
        newA = chainAList.copy; newA[lastA] = k;
        newB = chainBList.copy; newB[lastB] = k;
        // publish new lists and restore CURRENT/NEXT pointers to the matching list
        chainAList = newA;
        chainBList = newB;
        currentChain = if(curWasA) { chainAList } { chainBList };
        nextChain    = if(nextWasA) { chainAList } { chainBList };
        // rebuild both (non-destructive; uses <<> internally in rebuildUnbound)
        this.rebuild(currentChain);
        this.rebuild(nextChain);
        // (optional) inform display
        if(display.notNil and: { display.respondsTo(\showMutation) }) {
            display.showMutation(\setSourcesBoth, [k], nextChain);
        };
        ^this
    }
    //KEEP
    setDefaultSource { arg key;
        var k;
        // update the instance default; does not modify existing chains immediately
        k = key ? \testmelody;
        defaultSource = k;
        ^this
    }
    // ─── diagnostics helpers ──────────────────────────────────────
    //REVIEW ALL THESE:
    effectiveCurrent { ^this.effectiveListForInternal(currentChain) }
    effectiveNext { ^this.effectiveListForInternal(nextChain) }
    bypassKeysCurrent { ^this.bypassKeysForListInternal(currentChain) }
    bypassKeysNext { ^this.bypassKeysForListInternal(nextChain) }
    reset {
        var sinkAKey, sinkBKey, canRun;
        sinkAKey = \chainA;
        sinkBKey = \chainB;
        chainAList = [sinkAKey, defaultSource];
        chainBList = [sinkBKey, defaultSource];
        bypassA.clear;
        bypassB.clear;
        currentChain = chainAList;
        nextChain = chainBList;
        canRun = this.ensureServerTree;
        if(canRun.not) { ^this };
        Server.default.bind({
            // soft reset: stop both, then rebuild clean connections
            Ndef(sinkAKey).stop;
            Ndef(sinkBKey).stop;
            // Rebuild NEXT first (stays stopped), then CURRENT (plays)
            this.rebuildUnbound(nextChain);
            this.rebuildUnbound(currentChain);
        });
        // enforce exclusive invariant (Option A): CURRENT audible; NEXT silent
        this.enforceExclusiveCurrentOptionA(0.1);
        if(display.notNil) { display.showReset(currentChain, nextChain) };
    }

    // ───────────────────────────────────────────────────────────────
    // internal helpers (lowercase, no leading underscore)
    // ───────────────────────────────────────────────────────────────

    // POSSIBLY OBSOLETE:
    setNextListInternal { arg newList;
        var isAList;
        isAList = nextChain === chainAList;
        if(isAList) { chainAList = newList; nextChain = chainAList } { chainBList = newList; nextChain = chainBList };
    }

    // POSSIBLY OBSOLETE:
    bypassDictForListInternal { arg listRef;
        ^if(listRef === chainAList) { bypassA } { bypassB }
    }
    // POSSIBLY OBSOLETE:
    bypassKeysForListInternal { arg listRef;
        var dict, keysBypassed;
        dict = this.bypassDictForListInternal(listRef);
        keysBypassed = Array.new;
        dict.keysValuesDo({ arg key, state;
            if(state == true) { keysBypassed = keysBypassed.add(key) };
        });
        ^keysBypassed
    }

    // KEEP AROUND BUT BETTER USE makepasstrhough method in NChain
    ensureStereoInternal { arg key;
        var proxyBus, needsInit;
        proxyBus = Ndef(key).bus;
        needsInit = proxyBus.isNil or: { proxyBus.rate != \audio } or: { proxyBus.numChannels != defaultNumChannels };
        if(needsInit) {
            Ndef(key).ar(defaultNumChannels);
        };
    }
    // KEEP

// new for v1.0.5
// added to invoke at beginning of setupStaticNdefs 
	ensureServerReady{
        ~serv = Server.local;
        if (~serv.serverRunning.not) {
            ~serv.boot;
            ~serv.waitForBoot; // allowed in your safe-reset pattern
            ~serv.bind({
                ~serv.initTree;
                ~serv.defaultGroup.freeAll;
            });
        };
        ^ this
    }

    // Non-destructive: guard only; do not reset here
    ensureServerTree {
        var serverIsRunning;
        serverIsRunning = Server.default.serverRunning;
        ^serverIsRunning
    }
    // REVIEW: possibly obsolete
    // v0.4.6 change
    enforceExclusiveCurrentOptionA { arg fadeCurrent = 0.1;
        var currentSink, nextSink, chans, fadeCur;
        currentSink = currentChain[0];
        nextSink = nextChain[0];
        chans = defaultNumChannels;
        fadeCur = fadeCurrent.clip(0.05, 0.2);
        Server.default.bind({
            // CURRENT: robust \in.ar, stereo shape pinned, playing
            Ndef(currentSink, { \in.ar(chans) });
            Ndef(currentSink).mold(chans, \audio); // authoritative shape
            Ndef(currentSink).fadeTime_(fadeCur);
            if(Ndef(currentSink).isPlaying.not) {
                Ndef(currentSink).play(numChannels: chans);
            };
            // NEXT: hard-silence + ensure flag drops
            // 1) silence source, then .stop (no audio either way)
            Ndef(nextSink, { Silent.ar(chans) });
            Ndef(nextSink).mold(chans, \audio);
            Ndef(nextSink).fadeTime_(0.01);
            Ndef(nextSink).stop;
            // 2) drop monitor/flag deterministically, then re-establish silent sink
            Ndef(nextSink).end; // frees inner players, "stop listen" (NodeProxy help)
            Ndef(nextSink, { Silent.ar(chans) }); // keep NEXT present & silent for prebuild
            Ndef(nextSink).mold(chans, \audio);
            // do NOT play NEXT
        });
        ^this
    }

    // POSSIBLY OBSOLETE:
    effectiveListForInternal { arg listRef;
        var dict, resultList, lastIndex, isProcessor, isBypassed;
        dict = this.bypassDictForListInternal(listRef);
        resultList = Array.new;
        lastIndex = listRef.size - 1;
        listRef.do({ arg key, indexPosition;
            isProcessor = (indexPosition > 0) and: (indexPosition < lastIndex);
            isBypassed = isProcessor and: { dict[key] == true };
            if((indexPosition == 0) or: { indexPosition == lastIndex }) {
                resultList = resultList.add(key);
            }{
                if(isBypassed.not) { resultList = resultList.add(key) };
            };
        });
        ^resultList
    }

    // PROBABLY OBSOLETE; if we call rebuild here, it should actually call the one in NChain
    rebuild { arg listRef;
        var whichChain, canRun;
        whichChain = if(listRef === currentChain) { \current } { \next };
        canRun = this.ensureServerTree;
        if(canRun.not) { ^this };
        Server.default.bind({
            this.rebuildUnbound(listRef);
        });
        if(display.notNil) {
            display.showRebuild(whichChain, listRef, this.effectiveListForInternal(listRef));
        };
    }
    // PROBABLY OBSOLETE: the chains gets rewired inside NChain
    // Internal rebuild that assumes we are already inside a server bind (no resets)
    rebuildUnbound { arg listRef;
        var effective, indexCounter, leftKey, rightKey, sinkKey, hasMinimum, shouldPlay, isPlaying;
        hasMinimum = listRef.size >= 2;
        if(hasMinimum.not) { ^this };
        // (NEW 2D) Ensure Ndefs for symbols present in the *declared* chain (includes bypassed ones)
        if(processorLib.notNil) {
            processorLib.ensureFromChain(listRef, defaultNumChannels);
        };
        // From here on, this is your original "effective / do / connect"
        effective = this.effectiveListForInternal(listRef);
        effective.do({ arg keySymbol; this.ensureStereoInternal(keySymbol) });
        indexCounter = 0;
        while({ indexCounter < (effective.size - 1) }, {
            leftKey = effective[indexCounter];
            rightKey = effective[indexCounter + 1];
            Ndef(leftKey) <<> Ndef(rightKey);
            indexCounter = indexCounter + 1;
        });
        sinkKey = effective[0];
        shouldPlay = (listRef === currentChain);
        isPlaying = Ndef(sinkKey).isPlaying;
        if(shouldPlay) {
            if(isPlaying.not) { Ndef(sinkKey).play(numChannels: defaultNumChannels) };
        }{
            if(isPlaying) { Ndef(sinkKey).stop };
        };

        hasMinimum = listRef.size >= 2;
        if(hasMinimum.not) { ^this };
        effective = this.effectiveListForInternal(listRef);
        effective.do({ arg keySymbol; this.ensureStereoInternal(keySymbol) });
        indexCounter = 0;
        while({ indexCounter < (effective.size - 1) }, {
            leftKey = effective[indexCounter];
            rightKey = effective[indexCounter + 1];
            Ndef(leftKey) <<> Ndef(rightKey);
            indexCounter = indexCounter + 1;
        });
        sinkKey = effective[0];
        shouldPlay = (listRef === currentChain);
        isPlaying = Ndef(sinkKey).isPlaying;
        if(shouldPlay) {
            if(isPlaying.not) { Ndef(sinkKey).play(numChannels: defaultNumChannels) };
        }{
            if(isPlaying) { Ndef(sinkKey).stop };
        };
    }

    // KEEP
    isReady {
        ^ready
    }

    // AppClock polling; onReadyFunc is optional
    waitUntilReady { arg timeoutSec = 2.0, pollSec = 0.05, onReadyFunc = nil;
        var startTime, tick;
        startTime = Main.elapsedTime;
        AppClock.sched(0, {
            tick = {
                if(this.readyConditionOk) {
                    ready = true;
                    if(onReadyFunc.notNil) { onReadyFunc.value };
                    nil
                }{
                    if((Main.elapsedTime - startTime) > timeoutSec) {
                        // timed out; leave 'ready' as-is
                        nil
                    }{
                        AppClock.sched(pollSec, tick)
                    }
                }
            };
            tick.value;
            nil
        });
        ^this
    }
    // ---- Ready helpers (internal; no leading underscore) ----

    // PROBABLY OBSOLETE:
    // light background poll started from init (OPTION A)
    startReadyPoll {
        var alreadyTrue;
        alreadyTrue = this.readyConditionOk;
        if(alreadyTrue) { ready = true; ^this };
        this.waitUntilReady(2.0, 0.05, { nil });
        ^this
    }

    // PROBABLY OBSOLETE:
    // compute the readiness condition; no server ops here
    readyConditionOk {
        var curSink, nxtSink, serverOk, curBus, nxtBus, busesOk, currentPlaying;
        curSink = currentChain[0];
        nxtSink = nextChain[0];
        serverOk = Server.default.serverRunning;
        curBus = Ndef(curSink).bus;
        nxtBus = Ndef(nxtSink).bus;
        busesOk = curBus.notNil and: { nxtBus.notNil }
        and: { curBus.rate == \audio } and: { nxtBus.rate == \audio };
        currentPlaying = Ndef(curSink).isPlaying;
        ^(serverOk and: { busesOk } and: { currentPlaying })
    }

    //------------------------------------------------------------------------
    // REVIEW CAREFULLY: this will be important; 
    //but work out the Ndef handling and NChain integration first 
    //------------------------------------------------------------------------
    handleCommand { |oscPath|
     var path;
     path = oscPath.asString;
     if(~ct_applyOSCPathToMPB.notNil) {
     ~ct_applyOSCPathToMPB.(path, this, display);
     } {
     ("[MPB] handleCommand: " ++ path ++ " → no handler found").warn;
     };
     ^this;
    }

    // --- Added in v0.4.9: class-side helpers ---------------------------------

    // NEEDS REVISION TO MATCH CURRENT STATE OF CLASS
    *help {
        var text;
        text = "
MagicPedalboard.help — quick guide (class-side)

Quick start
-----------
(
var mpb;
mpb = MagicPedalboard.new(nil);  // optional display adaptor may be passed
mpb.printChains;                    // see CURRENT/NEXT
// NEXT-chain edits:
mpb.add(\\delay);                   // append before source
mpb.bypass(\\delay, true);          // bypass in NEXT
mpb.setSource(\\testmelody);        // set NEXT source
// Commit and listen:
mpb.switchChain(0.1);               // crossfade CURRENT<->NEXT (80–200 ms clamp)
// Diagnostics:
mpb.printChains; mpb.effectiveCurrent; mpb.effectiveNext;
)

Design highlights
- Chains are Arrays of Symbols: [sink, processors..., source]
- Embedding: Ndef(left) <<> Ndef(right)
- create sinks \\chainA and \\chainB; CURRENT plays, NEXT is prepared/silenced
- Mutators act on NEXT (add/addAt/removeAt/swap/bypass/bypassAt/clearChain/setSource)
- CURRENT helpers for bypassing and source changes are also available
- Non-destructive rebuilds; .reset is a guarded soft reset
";
        text.postln;
        text
    }

    // NEEDS REVISION TO MATCH CURRENT STATE OF CLASS
    *api {
        var api;
        api = IdentityDictionary[
            // construction & display
            \ctor         -> "MagicPedalboard.new(displayOrNil)",
            \display      -> "setDisplay(disp), setProcessorLib(lib), setDefaultSource(key)",

            // status & printing
            \status       -> "printChains(), effectiveCurrent(), effectiveNext(), bypassKeysCurrent(), bypassKeysNext()",

            // play control
            \play         -> "playCurrent(), stopCurrent(), switchChain([fadeTime=0.1])",

            // NEXT-chain editing
            \next_edit    -> "add(key), addAt(key, index), removeAt(index), swap(iA, iB), clearChain(), bypass(key[,state]), bypassAt(index[,state]), setSource(key)",

            // CURRENT-chain helpers
            \current_edit -> "bypassCurrent(key[,state]), bypassAtCurrent(index[,state]), setSourceCurrent(key), setSourcesBoth(key)",

            // lifecycle / invariants
            \invariants   -> "enforceExclusiveCurrentOptionA([fade])",
            \reset        -> "reset()  // guarded soft reset with rebuilds",

            // diagnostics / readiness
            \ready        -> "isReady(), waitUntilReady([timeout,poll,onReadyFunc])"
        ];
        api.postln;
        api
    }

    // PROBABLY OBSOLETE. A new one might be handy but probably not strictly necessary.
    *test {
        var mpb;
        mpb = MagicPedalboard.new(nil);
        // A tiny smoke test that exercises the common NEXT->switch flow.
        mpb.add(\delay);
        mpb.setSource(\testmelody);
        mpb.switchChain(0.1);
        mpb.printChains;
        mpb
    }
}


/*
20251013-1924:new plan

New approach

[DONE]: setupStaticNdefs {}

LPpedalboard needs to set up the STATIC Ndefs:
  [DONE]pedalboardIn: 
        this one should default to eternal audio (hex) 
        but we want a test ndef which sets the input to a synthesised 
        source so that we can verify that things work without needed 
        a guitar and gobbins.

    connected to...
  [DONE] instance of NChain 
        (theChain for now; we may or may not need chainAchainB at this
        stage). The chain will start empty
        
    connected to...
  [DONE] pedalboardOut:
        this one needs to have metering which is being sent to 
        /sendpeakrmsA (or whatever it's called)
  
    connected to...
  NOW we have a choice; we could connect to activeOut which would 
  always be playing with the .play method. Simple. Or we just .play
  the pedalboardOut directly but we will have to think how we manage
  active, bypass, etc. From a stage-performance point of view, there is 
  some value in being able to tap the signal in different places (e.g.
  monitor-out); let's keep thinking.

  LPPedalboard has knowledge of the LPLibrary. Need an elegant way of 
  being able to fetch algorithms from the library when inserting into
  Nchain.

*/