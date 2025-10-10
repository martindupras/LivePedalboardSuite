/* MagicPedalboard.sc v0.5.1.5

v0.5.1.3 moved docs (*help, *api, *test) to MagicPedalboard_docs.sc

v0.5.1.2 remove commented out code.

v0.5.1.1 Try approach where chain is always ending with \chainXout, and the ouput is always \lpbOut. Switching becomes simply Ndef(\lpbOut).set(\in, Ndef(\chainAout).


v0.5.1 General tidy of class code and simplifcation.
 changed \in.ar(defaultNumChannels); to \in.ar(0!defaultNumChannels); Argument is an array of channel indices, not a count.


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

// ------------------------------------------------------------------
// NOTE: Detailed class-side helpers (*help, *api, and an interactive *test/demo)
// were intentionally moved into the companion file
//    MagicPedalboard/MagicPedalboard_docs.sc
// Evaluate that file in the SuperCollider IDE or load it via File(...).interpret
// to access the long-form help, API dictionary, and the demo-style *test.
//
// This main class file contains a small lightweight class-side *test (for CI/dev)
// that checks presence of key selectors and performs safe, non-audio calls by default.
// For interactive examples and demos use the docs file.
// ------------------------------------------------------------------

MagicPedalboard : Object {
    // ───────────────────────────────────────────────────────────────
    // class metadata
    // ───────────────────────────────────────────────────────────────
    classvar <version;
    // ───────────────────────────────────────────────────────────────
    // instance state
    // ───────────────────────────────────────────────────────────────
    var < currentChain; // read-only pointer to Array of Symbols
    var < nextChain; // read-only pointer to Array of Symbols
    var chainAList; // [\chainA, ...processors..., source]
    var chainBList; // [\chainB, ...processors..., source]
    var bypassA; // IdentityDictionary: key(Symbol) -> Bool
    var bypassB; // IdentityDictionary: key(Symbol) -> Bool
    var < defaultNumChannels;
    var < defaultSource;
    var < display; // optional display adaptor
    var < processorLib;
    var < ready; 

    var <> activeChain;
    var <> nextChain;

    *initClass {
        var text;
        version = "v0.5.1.5";
        text = "MagicPedalboard " ++ version;
        text.postln;
    }

    // A lightweight class-side test for CI/dev: checks that public selectors exist
    *test { arg runRuntimeChecks = false;
        var missing = Array.new;
        var instance;
        var selectors = [
            // construction & basic API
            \new, \setDisplay, \setProcessorLib,
            // playback
            \playCurrent, \stopCurrent, \switchChain,
            // mutators
            \add, \addAt, \removeAt, \swap, \clearChain, \bypass, \bypassAt,
            // current-chain helpers
            \bypassCurrent, \bypassAtCurrent, \setSourceCurrent, \setSourcesBoth,
            // diagnostics
            \printChains, \effectiveCurrent, \effectiveNext, \isReady
        ];

        // check selectors exist on the class (instance methods)
        selectors.do { |sym|
            if(MagicPedalboard.respondsTo(sym).not) { missing = missing.add(sym) }
        };

        if(missing.notEmpty) {
            "Missing selectors on MagicPedalboard: %".format(missing).postln;
            ^missing
        };

        // Create a lightweight instance (display nil) and exercise a few calls that don't need a running server
        instance = MagicPedalboard.new(nil);
        instance.printChains;     // should not throw
        instance.setProcessorLib(nil);
        instance.setDefaultSource(\testmelody);
        instance.clearChain;      // idempotent
        instance.setSourcesBoth(\testmelody);

        // Optionally attempt runtime calls which require a running server; guarded by runRuntimeChecks flag
        if(runRuntimeChecks) {
            try {
                instance.playCurrent;
                instance.stopCurrent;
                instance.switchChain(0.1);
            } { |err|
                "Runtime check error: %".format(err).postln;
            };
        };

        "MagicPedalboard.test OK (selectors present, basic calls exercised)".postln;
        ^instance
    }

    *new { arg disp = nil;
        ^super.new.init(disp);
    }
    init { arg disp;
        var sinkFunc;
        display = disp;
        defaultNumChannels = 2; // become 6 when hexaphonic

        // REVIEW WHERE SOURCE IS DEFINED AND CHANGE TO \silent or something
        defaultSource = \ts0;
        
        // the default re-routable "pass-through" Ndef function
        // sinkFunc = { arg inSignal; inSignal };
        sinkFunc = {
            var inputSignal;
            inputSignal = \in.ar(0!defaultNumChannels); //Fixed! We need to ! to numChannels. IMPORTANT SYNTAX!
            inputSignal
        };

        Ndef(\chainA, sinkFunc); // to be retired
        Ndef(\chainB, sinkFunc); // to be retired


        Ndef(\lpbOut, sinkFunc);
        Ndef(\chainAout, sinkFunc);
        Ndef(\chainBout, sinkFunc);
        // If the code inside sends server messages, they’re gathered and sent together with a single timestamp, preserving order

        Server.default.bind({
            Ndef(\lpbOut).ar(0!defaultNumChannels); // typically 2
            Ndef(\chainA).ar(0!defaultNumChannels); 
            Ndef(\chainB).ar(0!defaultNumChannels);
        });
        chainAList = [\chainAout, defaultSource];
        chainBList = [\chainBout, defaultSource];
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
            display.showInit(this, version, currentChain, nextChain);
        };

        // REVIEW TO SEE IF NEEDED:
        // enforce exclusive invariant (Option A) at first bring-up
        this.enforceExclusiveCurrentOptionA(0.1);
        // set initial state; the poll will flip it once conditions are true
        ready = false;

        // OPTION A: enable background poll (comment out if you prefer Option B)
        this.startReadyPoll;
        ^this
    }


    // ───────────────────────────────────────────────────────────────
    // public API
    // ───────────────────────────────────────────────────────────────
    // add a setter (public)
    setProcessorLib { arg lib;
        processorLib = lib;
    }

    // REVIEW: IS THIS STILL THE WAY TO SET THE DISPLAY?
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
    // REVIEW: IS THIS STILL NEEDED?

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

    // REVIEW: IS THIS STILL NEEDED?
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
}
