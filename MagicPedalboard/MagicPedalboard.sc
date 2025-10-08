// MagicPedalboard.sc
// v0.5.0 silent-defaults + initial source args + setSourceA/B
// MD 20251006-1718

/*
Purpose
- Start both chains as [\chainA, \stereoSilence] and [\chainB, \stereoSilence] with \stereoSilence explicitly defined as stereo silence.
- Allow optional constructor args aSource/bSource to pre-set tail sources (else both use \stereoSilence).
- Provide explicit setSourceA / setSourceB (and setSources) that update the correct tail regardless of CURRENT/NEXT.
- Preserve your existing invariants (CURRENT plays; NEXT silent) and "ready" semantics.

*/

MagicPedalboard : Object {
    // ───────────────────────────────────────────────────────────────
    // class metadata
    // ───────────────────────────────────────────────────────────────
    classvar <version;

    // ───────────────────────────────────────────────────────────────
    // instance state
    // ───────────────────────────────────────────────────────────────
    var <currentChain;          // read-only pointer to Array of Symbols
    var <nextChain;             // read-only pointer to Array of Symbols
    var chainAList;             // [\chainA, ...processors..., source]
    var chainBList;             // [\chainB, ...processors..., source]
    var bypassA;                // IdentityDictionary: key(Symbol) -> Bool
    var bypassB;                // IdentityDictionary: key(Symbol) -> Bool
    var <defaultNumChannels;
    var <defaultSource;
    var <display;               // optional display adaptor
    var <processorLib;
    var <ready;

    *initClass {
        var text;
        version = "v0.5.0";
        text = "MagicPedalboard " ++ version;
        text.postln;
    }

    *new { arg disp = nil, aSource = nil, bSource = nil;
        ^super.new.init(disp, aSource, bSource)
    }

    init { arg disp, aSource = nil, bSource = nil;
        var sinkFunc, useA, useB;

        display = disp;
        defaultNumChannels = 2;
        defaultSource = \stereoSilence;

        // --- ensure sinks and silent source proxies exist with correct shape
        sinkFunc = {
            var inputSignal;
            inputSignal = \in.ar(defaultNumChannels);
            inputSignal
        };

        Ndef(\chainA, sinkFunc);
        Ndef(\chainB, sinkFunc);

        // Define canonical silent stereo source \stereoSilence explicitly
        Server.default.bind({
            if (Ndef(\stereoSilence).source.isNil) { Ndef(\stereoSilence, { Silent.ar(defaultNumChannels) }) };
            Ndef(\stereoSilence).ar(defaultNumChannels);
            // ensure sink buses audio-rate early (prevents kr-meter races)
            Ndef(\chainA).ar(defaultNumChannels);
            Ndef(\chainB).ar(defaultNumChannels);
        });

        // --- build chain lists with default silent tail
        chainAList = [\chainA, defaultSource];
        chainBList = [\chainB, defaultSource];

        // --- optionally apply starting sources (nil-safe)
        useA = (aSource ?? { defaultSource }).asSymbol;
        useB = (bSource ?? { defaultSource }).asSymbol;
        if (useA != defaultSource) { this.setSourceA(useA) } { /* keep \stereoSilence */ };
        if (useB != defaultSource) { this.setSourceB(useB) } { /* keep \stereoSilence */ };

        bypassA = IdentityDictionary.new;
        bypassB = IdentityDictionary.new;

        currentChain = chainAList;
        nextChain = chainBList;

        // Prebuild NEXT (stays stopped) then CURRENT (plays) — CURRENT is silent if using \stereoSilence
        Server.default.bind({
            this.rebuildUnbound(nextChain);
            this.rebuildUnbound(currentChain);
        });

        if (display.notNil) {
            display.showInit(this, version, currentChain, nextChain);
        };

        // enforce exclusive invariant (Option A) at first bring-up
        this.enforceExclusiveCurrentOptionA(0.1);

        // Ready tracking (unchanged semantic)
        ready = false;
        this.startReadyPoll;

        ^this
    }

    // ─── public helpers (added) ───────────────────────────────────

    setSourceA { arg sourceSym;
        var lastA, wasCurA, wasNextA, newA, k;
        k = sourceSym.asSymbol;
        lastA = chainAList.size - 1;
        wasCurA = (currentChain === chainAList);
        wasNextA = (nextChain === chainAList);
        newA = chainAList.copy; newA[lastA] = k;
        chainAList = newA;
        if (wasCurA) { currentChain = chainAList };
        if (wasNextA) { nextChain = chainAList };
        this.rebuild(chainAList);
        ^this
    }

    setSourceB { arg sourceSym;
        var lastB, wasCurB, wasNextB, newB, k;
        k = sourceSym.asSymbol;
        lastB = chainBList.size - 1;
        wasCurB = (currentChain === chainBList);
        wasNextB = (nextChain === chainBList);
        newB = chainBList.copy; newB[lastB] = k;
        chainBList = newB;
        if (wasCurB) { currentChain = chainBList };
        if (wasNextB) { nextChain = chainBList };
        this.rebuild(chainBList);
        ^this
    }

    setSources { arg aSym = nil, bSym = nil;
        var aOk, bOk;
        aOk = aSym.notNil; bOk = bSym.notNil;
        if (aOk) { this.setSourceA(aSym) };
        if (bOk) { this.setSourceB(bSym) };
        ^this
    }

    // ─── existing API follows (unchanged except one tiny default tweak) ─────

    setProcessorLib { arg lib; processorLib = lib; }

    setDisplay { arg disp;
        var shouldShow;
        display = disp;
        shouldShow = display.notNil;
        if (shouldShow) { display.showInit(this, version, currentChain, nextChain) };
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
        ++ " setSource(key) [next], setSourceCurrent(key) [current], setSourceA(key), setSourceB(key), setSources(a,b)\n";
        text.postln;
    }

    // … (rest of your methods remain exactly as before) …

    setDefaultSource { arg key;
        var k;
        // update the instance default; does not modify existing chains immediately
        k = key ? \stereoSilence;   // <<< changed default to \stereoSilence (was \testmelody)
        defaultSource = k;
        ^this
    }

    // (No other changes below this point)
    // — your switchChain, add/remove/swap/bypass*, effective*, rebuild*, ready*, etc remain unchanged —
}
