// MagicPedalboard-Compat_RebuildUnbound.sc
// v0.1.0
// MD 20251006-1753

/*
Purpose
- Provide a compatibility shim for MagicPedalboard>>rebuildUnbound(list)
- Accepts a chain list like [\chainA, \stereoSilence] or [\chainB, \stereoSilence]
- Updates the stored chain lists only; performs no server-bound rebuild.
Style
- var-first; descriptive; no server.sync; no non-local returns.
*/

+ MagicPedalboard {

    rebuildUnbound { arg list;
        var sink, src;

        sink = \chainA;
        src  = \stereoSilence;

        if (list.isArray) {
            if (list.size >= 1) { sink = list[0].asSymbol };
            if (list.size >= 2) { src  = list[1].asSymbol };
        };

        if (sink == \chainA) {
            chainAList = [\chainA, src];
        } {
            if (sink == \chainB) {
                chainBList = [\chainB, src];
            };
        };

        ^this
    }
}
