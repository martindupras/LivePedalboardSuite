// MagicPedalboard-Compat_Rebuild.sc
// v0.1.0
// MD 20251006-1836

/*
Purpose
- Provide MagicPedalboard>>rebuild(arg) as a compatibility shim because setSourceA/B currently call 'rebuild'.
- Accepts either:
  * an Array like [\chainA, \stereoSilence] or [\chainB, \stereoSilence], or
  * a Symbol \A or \B
- If rebuildUnbound exists, delegate to it. Else, update internal lists only (no DSP/server ops).

Style
- var-first; descriptive names; no server.sync; no non-local returns.
*/

+ MagicPedalboard {

    rebuild { arg whichOrList;
        var hasUnbound, sink, src, list, which, cur0, next0, isArrayArg;

        hasUnbound = this.respondsTo(\rebuildUnbound);
        isArrayArg = whichOrList.isArray;

        if (hasUnbound) {
            ^this.rebuildUnbound(whichOrList);
        };

        // --- fallback (no rebuildUnbound available): model-only update ---

        if (isArrayArg) {
            list = whichOrList;
            sink = (list.size > 0).if({ list[0].asSymbol }, { \chainA });
            src  = (list.size > 1).if({ list[1].asSymbol }, { \stereoSilence });
        }{
            which = whichOrList.asSymbol;
            sink = (which == \B).if({ \chainB }, { \chainA });
            src  = (sink == \chainB).if({
                (chainBList.isArray and: { chainBList.size > 1 }).if({ chainBList[1].asSymbol }, { \stereoSilence })
            },{
                (chainAList.isArray and: { chainAList.size > 1 }).if({ chainAList[1].asSymbol }, { \stereoSilence })
            });
            list = [sink, src];
        };

        // Update the stored lists
        if (sink == \chainA) { chainAList = [\chainA, src] } { chainBList = [\chainB, src] };

        // Keep currentChain / nextChain in sync if they point at this sink
        cur0  = (currentChain.isArray and: { currentChain.size > 0 }).if({ currentChain[0] }, { nil });
        next0 = (nextChain.isArray and: { nextChain.size > 0 }).if({ nextChain[0] }, { nil });

        if (cur0 == sink)  { currentChain = list.copy };
        if (next0 == sink) { nextChain   = list.copy };

        // Optional: let a display adapter summarize; ignore if not present
        this.display.tryPerform(\showRebuild, \current, list, list);

        ^this
    }
}