// LPPedalboard.sc 

// v1.0.2 added setupStaticNdefs method to create pedalboardIn, pedalboardOut, and theNChain
// v1.0.1 added some comments describing new strategy using NChain class

/*
 A/B pedalboard chain manager built on Ndefs.
 - Chains are Arrays of Symbols ordered [sink, …, source].
 - Uses JITLib embedding: Ndef(left) <<> Ndef(right).
 - Creates two sinks: \chainA and \chainB, and plays the current chain on init.
 - Most mutators act on the next chain; explicit current-chain bypass helpers are provided.
 - Optional display adaptor (MagicDisplay / MagicDisplayGUI) receives notifications, including detailed chain views.
 - Non-destructive rebuilds (no server resets during rebuild). Only .reset performs a safe server-tree reset.
// MD 2025-10-02 13:58
*/

/*
Supplementary header — What this class does & key dependencies
----------------------------------------------------------------
Overview
- Manages two signal chains (CURRENT and NEXT) as symbol arrays [sink, processors..., source],
  built with JITLib NodeProxies (Ndef) and connected using the embedding operator:
  Ndef(left) <<> Ndef(right). Switches are crossfaded; rebuilds are non-destructive.

Core responsibilities
- Materialize and keep \chainA / \chainB sinks alive at audio rate.
- Maintain CURRENT vs NEXT chains, with mutators that operate primarily on NEXT (e.g., add/remove/swap/bypass).
- Provide safe, exclusive playback semantics (NEXT hard-silenced; CURRENT audible) and optional crossfade switch.

Relies on (classes / facilities expected on the classpath)
- JITLib / NodeProxy system: Ndef, embedding via <<>.
- SuperCollider server primitives: Server, Ndef buses, AppClock for light scheduling.
- Optional display adaptor (MagicDisplay / MagicDisplayGUI) for chain prints, status, and meter UX.
- Optional processor library (processorLib) that can .ensureFromChain(list, numChannels).

External interactions
- This class does not reset the server during rebuild; only .reset implements a guarded tree reset.
- Exposes a simple dispatcher .handleCommand(path) that defers to ~ct_applyOSCPathToMPB if present.

Notes
- This update only adds class-side utilities (*help, *api, *test) and a supplementary header.
- No behavior changes to public or internal instance methods (including the existing instance help).
*/

LPPedalboard : Object {
    // ───────────────────────────────────────────────────────────────
    // class metadata
    // ───────────────────────────────────────────────────────────────
    classvar <version;
    // ───────────────────────────────────────────────────────────────
    // instance state
    // ───────────────────────────────────────────────────────────────
    var < currentChain; // read-only pointer to Array of Symbols
    var <nextChain; // read-only pointer to Array of Symbols
    var chainAList; // [\chainA, ...processors..., source]
    var chainBList; // [\chainB, ...processors..., source]
    var bypassA; // IdentityDictionary: key(Symbol) -> Bool
    var bypassB; // IdentityDictionary: key(Symbol) -> Bool
    var < defaultNumChannels;
    var < defaultSource;
    var < display; // optional display adaptor
    var < processorLib;
    var < ready; // <-- ADD this line


    // new for v1.0.2
    var < theNChain
    var pedalboardInSym = \pedalboardIn;
	var pedalboardOutSym = \pedalboardOut;

    *initClass {
        var text;
        version = "v1.0.1";
        text = "LPPedaloard " ++ version;
        text.postln;
    }
    *new { arg disp = nil, aProcessorLib;
        ^super.new.init(disp, );
    }

/*
20251013-1924:new plan

Let's think carefully what revisions are needed below to implement new approach. 

LPpedalboard needs to set up the STATIC Ndefs:
  pedalboardIn: 
        this one should default to eternal audio (hex) 
        but we want a test flat which sets the input to a synthesised 
        source so that we can verify that things work without needed 
        a guitar and gobbins.

    connected to...
  instance of NChain 
        (chainA for now; we may or may not need chainB at this
        stage). The chain will start empty
        
    connected to...
  pedalboardOut:
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

  pedalboardOut: this one should default 
*/
    init { arg disp, aProcessorLib;


        var sinkFunc;
        display = disp;
		processorLib = aProcessorLib;
        defaultNumChannels = 2;
        defaultSource = \ts0; // silence as source
        // less good than the version below
        // sinkFunc = { arg inSignal; inSignal };
        sinkFunc = {
            var inputSignal;
            inputSignal = \in.ar(defaultNumChannels);
            inputSignal
        };

		Ndef(\lpbOut, sinkFunc);  //new
        Ndef(\chainAout, sinkFunc);
        Ndef(\chainBout, sinkFunc);

        Ndef(\chainA, sinkFunc);  //to be replaced
        Ndef(\chainB, sinkFunc);
        // Guarantee sink buses are audio-rate early (prevents kr-meter races)
        Server.default.bind({
            Ndef(\chainA).ar(defaultNumChannels); // typically 2
            Ndef(\chainB).ar(defaultNumChannels);
        });
        chainAList = [\chainA, defaultSource];
        chainBList = [\chainB, defaultSource];
        bypassA = IdentityDictionary.new;
        bypassB = IdentityDictionary.new;
        currentChain = chainAList;
        nextChain = chainBList;
        Server.default.bind({
            this.rebuildUnbound(nextChain); // stays stopped
            this.rebuildUnbound(currentChain); // plays
        });
/*        this.rebuild(currentChain);
        this.rebuild(nextChain);*/
/* Server.default.bind({
 Ndef(\chainA).play(numChannels: defaultNumChannels);
 });*/
        if(display.notNil) {
            display.sendPaneText(\left, currentChain.asString);
			display.sendPaneText(\right,nextChain.asString);
        };
        // enforce exclusive invariant (Option A) at first bring-up
        this.enforceExclusiveCurrentOptionA(0.1);
        // set initial state; the poll will flip it once conditions are true
        ready = false;
        // OPTION A: enable background poll (comment out if you prefer Option B)
        this.startReadyPoll;

		this.initChainTest();


        ^this
    }

    setupStaticNdefs {
        // here create the pedalboardIn and pedalboardOut Ndefs and instantiate theNChain
        
		Ndef(pedalboardInSym.asSymbol).reshaping_(\elastic).source = {
			\in.ar(0 ! numChannels)   // instance width, not a hard-coded 6
		};

		Ndef(cpedalboardOutSym.asSymbol).reshaping_(\elastic).source = {
			\in.ar(0 ! numChannels)   // instance width, not a hard-coded 6
        };
        
        // REVIEW: first argument is the name of the chain itself; adapt 
        //NChain class to also accept arguments argDisplay (for LPDisplay)
        // and argProcLib (for LPProcessorLibrary)

        //theNChain = NChain.new(\pedalboardChainA, display, processorLib);
        theNChain = NChain.new(\pedalboardChainA);

        // connect them all 
        Ndef(pedalboardInSym.asSymbol) <<> theNChain <<> Ndef(pedalboardOutSym.asSymbol);

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
    // Detailed printing routed through display if available
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
    // Crossfading chain switch (default 0.1 s, clamped to ~80–200 ms)
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
    add { arg key;
        var insertIndex;
        insertIndex = nextChain.size - 1;
        this.addAt(key, insertIndex);
        if(display.notNil) { display.showMutation(\add, [key], nextChain) };
    }
    addAt { arg key, index;
        var indexClamped, newList;
        indexClamped = index.clip(1, nextChain.size - 1);
        newList = nextChain.insert(indexClamped, key);
        this.setNextListInternal(newList);
        this.rebuild(nextChain);
        if(display.notNil) { display.showMutation(\addAt, [key, indexClamped], nextChain) };
    }
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
    setSource { arg key;
        var newList, lastIndex;
        lastIndex = nextChain.size - 1;
        newList = nextChain.copy;
        newList[lastIndex] = key;
        this.setNextListInternal(newList);
        this.rebuild(nextChain);
        if(display.notNil) { display.showMutation(\setSource, [key], nextChain) };
    }
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
    setDefaultSource { arg key;
        var k;
        // update the instance default; does not modify existing chains immediately
        k = key ? \testmelody;
        defaultSource = k;
        ^this
    }
    // ─── diagnostics helpers ──────────────────────────────────────
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
/* OLDreset {
 var sinkAKey, sinkBKey;
 sinkAKey = \chainA;
 sinkBKey = \chainB;
 chainAList = [sinkAKey, defaultSource];
 chainBList = [sinkBKey, defaultSource];
 bypassA.clear;
 bypassB.clear;
 currentChain = chainAList;
 nextChain = chainBList;
 // SAFE server reset ONLY here, using Server.default.* (not 's')
 Server.default.waitForBoot({
 Server.default.bind({
 Server.default.initTree;
 Server.default.defaultGroup.freeAll;
 this.rebuildUnbound(nextChain);
 this.rebuildUnbound(currentChain);
 Ndef(sinkBKey).stop;
 Ndef(sinkAKey).play(numChannels: defaultNumChannels);
 });
 });
 if(display.notNil) { display.showReset(currentChain, nextChain) };
 } */
    // ───────────────────────────────────────────────────────────────
    // internal helpers (lowercase, no leading underscore)
    // ───────────────────────────────────────────────────────────────
    setNextListInternal { arg newList;
        var isAList;
        isAList = nextChain === chainAList;
        if(isAList) { chainAList = newList; nextChain = chainAList } { chainBList = newList; nextChain = chainBList };
    }
    bypassDictForListInternal { arg listRef;
        ^if(listRef === chainAList) { bypassA } { bypassB }
    }
    bypassKeysForListInternal { arg listRef;
        var dict, keysBypassed;
        dict = this.bypassDictForListInternal(listRef);
        keysBypassed = Array.new;
        dict.keysValuesDo({ arg key, state;
            if(state == true) { keysBypassed = keysBypassed.add(key) };
        });
        ^keysBypassed
    }
    ensureStereoInternal { arg key;
        var proxyBus, needsInit;
        proxyBus = Ndef(key).bus;
        needsInit = proxyBus.isNil or: { proxyBus.rate != \audio } or: { proxyBus.numChannels != defaultNumChannels };
        if(needsInit) {
            Ndef(key).ar(defaultNumChannels);
        };
    }
    // Non-destructive: guard only; do not reset here
    ensureServerTree {
        var serverIsRunning;
        serverIsRunning = Server.default.serverRunning;
        ^serverIsRunning
    }
    //
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
/*    enforceExclusiveCurrentOptionA { arg fadeCurrent = 0.1;
        var currentSink, nextSink, chans, fadeCur;
        currentSink = currentChain[0];
        nextSink = nextChain[0];
        chans = defaultNumChannels;
        fadeCur = fadeCurrent.clip(0.05, 0.2);
        Server.default.bind({
            // CURRENT: robust sink that consumes embedded input; ensure playing
            Ndef(currentSink, { \in.ar(chans) });
            Ndef(currentSink).ar(chans);
            Ndef(currentSink).fadeTime_(fadeCur);
            if (Ndef(currentSink).isPlaying.not) {
                Ndef(currentSink).play(numChannels: chans)
            };
            // NEXT: hard silence at the sink source; stop its monitor quickly
            Ndef(nextSink, { Silent.ar(chans) });
            Ndef(nextSink).ar(chans);
            Ndef(nextSink).fadeTime_(0.01);
            Ndef(nextSink).stop;
        });
        ^this
    }*/
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
    // Public rebuild: bundles server ops; guard only
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
    }
/*    rebuildUnbound { arg listRef;
        var effective, indexCounter, leftKey, rightKey, sinkKey, hasMinimum, shouldPlay, isPlaying;
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
    }*/
/*    // At end of rebuildUnbound
    rebuildUnbound { arg listRef;
        var effective, indexCounter, leftKey, rightKey, sinkKey, hasMinimum, shouldPlay, isPlaying;
/*        if(processorLib.notNil) {
            // Ask the lib to make sure each symbol in this chain has an Ndef with a function.
            // It will quietly do nothing for unknown keys.
            processorLib.ensureFromChain(listRef, defaultNumChannels);
        };*/
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
    }*/
/* OLD rebuildUnbound { arg listRef;
 var effective, indexCounter, leftKey, rightKey, sinkKey, hasMinimum;
 hasMinimum = listRef.size >= 2;
 if(hasMinimum.not) { ^this };
 effective = this.effectiveListForInternal(listRef);
 effective.do({ arg keySymbol;
 this.ensureStereoInternal(keySymbol);
 });
 indexCounter = 0;
 while({ indexCounter < (effective.size - 1) }, {
 leftKey = effective[indexCounter];
 rightKey = effective[indexCounter + 1];
 Ndef(leftKey) <<> Ndef(rightKey);
 });
        // sinkKey = effective[0];
        // if(listRef === currentChain) {
        //     Ndef(sinkKey).play(numChannels: defaultNumChannels);
        // }{
        //     Ndef(sinkKey).stop;
        // };
        // At the end of rebuildUnbound:
        sinkKey = effective[0];
        if(listRef === currentChain) {
            if(Ndef(sinkKey).isPlaying.not) { Ndef(sinkKey).play(numChannels: defaultNumChannels) };
        } {
            if(Ndef(sinkKey).isPlaying) { Ndef(sinkKey).stop };
        };
 } */
    // ---- Ready helpers (public API) ----
    // boolean snapshot (no server ops)
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
    // light background poll started from init (OPTION A)
    startReadyPoll {
        var alreadyTrue;
        alreadyTrue = this.readyConditionOk;
        if(alreadyTrue) { ready = true; ^this };
        this.waitUntilReady(2.0, 0.05, { nil });
        ^this
    }
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
    // handleCommand { |oscPath|
    //     var path;
    //     path = oscPath.asString;
    //
    //     // Route to your existing mutation logic
    //     // Update this if you use a different handler name
    //     if(this.respondsTo(\applyOSCPath)) {
    //         this.applyOSCPath(path);
    //     } {
    //         ("[MPB] handleCommand: " ++ path ++ " → no handler found").warn;
    //     };
    //
    //     ^this;
    // }
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
