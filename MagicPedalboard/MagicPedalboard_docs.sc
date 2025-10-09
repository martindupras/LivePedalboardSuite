// MagicPedalboard_docs.sc 
// v0.5.1.3
// MD 20251008-1959

+ MagicPedalboard {

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