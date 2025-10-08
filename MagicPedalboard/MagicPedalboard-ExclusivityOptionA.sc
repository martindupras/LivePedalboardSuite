// MagicPedalboard-ExclusivityOptionA.sc
// v0.1.2
// MD 20251006-1728

/*
Purpose
- Provide MagicPedalboard>>enforceExclusiveCurrentOptionA(fadeTime=0.1) without needing a 'currentKey' ivar.
- Infer the current side (\A or \B) from chain lists, then silence the NON-current chain at the source by
  swapping its tail to \stereoSilence (your canonical silent Ndef).

Style
- var-first; descriptive names; no server.sync; no non-local returns.
*/

+ MagicPedalboard {

    // Infer which chain is current (\A or \B) from available lists.
    inferCurrentKey {
        var list, sink;
        list = currentChain ? chainAList;
        sink = (list.isArray and: { list.size > 0 }).if({ list[0] }, { \chainA });
        ^((sink == \chainB).if({ \B }, { \A }))
    }

    enforceExclusiveCurrentOptionA { arg fadeTime = 0.1;
        var inferred, otherKey, otherSink, haveSetA, haveSetB;

        inferred  = this.inferCurrentKey;
        otherKey  = (inferred == \A).if({ \B }, { \A });
        otherSink = (otherKey == \A).if({ \chainA }, { \chainB });

        haveSetA = this.respondsTo(\setSourceA);
        haveSetB = this.respondsTo(\setSourceB);

        if (otherKey == \A) {
            if (haveSetA) { this.setSourceA(\stereoSilence) };
            chainAList = [\chainA, \stereoSilence];
        } {
            if (haveSetB) { this.setSourceB(\stereoSilence) };
            chainBList = [\chainB, \stereoSilence];
        };

        // Optional: notify display adapter (safe no-op if absent)
        this.display.tryPerform(\showStop, otherSink);

        // Note: 'fadeTime' reserved for a future crossfade; no DSP fade here (keeps it simple & reversible).
        ^this
    }
}