// LPDisplaySigChain.sc
// v0.9.7.2 — minimal [sink, ..., source] JITLib chain wrapper
// MD 2025-10-01
/*
 * 0.9.7.2 clearer local/parameter names + explanatory comments; NO logic changes (doc-only)
 *
 * Purpose
 * - Manage a simple symbol chain [sink, ..., source] using JITLib wiring:
 *   Ndef(left) <<> Ndef(right), where the left node reads \in.ar(2).
 * - Ensure stereo busses prior to wiring; play the sink.
 *
 * Typical usage
 *   LPDisplaySigChain.new([\outA, \srcA]).rebuild;       // wires and plays sink
 *   chain.setTailSource(\srcC).rebuild;                  // swap just the tail
 *   chain.chainToString  // "srcC → outA"
 *
 * Conventions
 * - *new returns ^super.new.init(...)
 * - Methods return ^this where appropriate; getters return values.
 */

LPDisplaySigChain {
    classvar classVersion = "0.9.7.2";

    var chainSymbols;  // Array(Symbol): [sink, ..., source]

    *initClass {
        ("LPDisplaySigChain v" ++ classVersion ++ " loaded (LivePedalboardDisplay)").postln;
    }

    *new { |chainSymbolsArray|
        ^super.new.init(chainSymbolsArray ?? { [] })
    }

    init { |chainSymbolsArray|
        chainSymbols = chainSymbolsArray.copy;
        ^this
    }

    size {
        ^chainSymbols.size
    }

    ensureStereo { |ndefKey|
        /*
         * Pre-arm an Ndef as a 2-channel audio node if its bus is missing or not stereo.
         * This prevents wiring failures when we connect nodes with <<>.
         */
        var ndefBus = Ndef(ndefKey).bus;
        if (ndefBus.isNil or: { ndefBus.rate != \audio } or: { ndefBus.numChannels != 2 }) {
            Ndef(ndefKey).ar(2);
        };
        ^this
    }

    rebuild {
        /*
         * Wire the chain left-to-right:
         *   chainSymbols = [sink, mid1, mid2, source]
         * becomes:
         *   Ndef(sink) <<> Ndef(mid1);  Ndef(mid1) <<> Ndef(mid2);  Ndef(mid2) <<> Ndef(source)
         * and then play the sink stereo.
         */
        var chainSize  = chainSymbols.size;
        var linkIndex  = 0;

        if (chainSize < 2) {
            "LPDisplaySigChain: need at least [sink, source]".postln;
            ^this
        };

        chainSymbols.do { |ndefSymbol| this.ensureStereo(ndefSymbol) };

        while({ linkIndex < (chainSize - 1) }, {
            Ndef(chainSymbols[linkIndex]) <<> Ndef(chainSymbols[linkIndex + 1]);
            linkIndex = linkIndex + 1;
        });

        Ndef(chainSymbols[0]).play(numChannels: 2);  // play the sink
        ^this
    }

    chainToString {
        // For display we show "source → ... → sink"
        var forwardList = chainSymbols.copy.reverse;
        ^forwardList.collect(_.asString).join(" → ")
    }

    setTailSource { |tailSourceSymbol|
        // Replace/append the final element (source) and keep the chain consistent.
        var newSourceSymbol = tailSourceSymbol.asSymbol;

        if (chainSymbols.size >= 2) {
            chainSymbols[chainSymbols.size - 1] = newSourceSymbol;
        } {
            chainSymbols = chainSymbols.add(newSourceSymbol);
        };

        ^this.rebuild
    }

    symbols {
        // Read-only copy so external code doesn’t mutate internal state.
        var symbolsCopy = chainSymbols.copy;
        ^symbolsCopy
    }



	////////
	// --- Utility: docs & smoke test (add-only) -----------------------------

*help {
    var lines;
    lines = [
        "LPDisplaySigChain — purpose:",
        "  Wrap a symbol chain [sink, ..., source] and wire via:",
        "    Ndef(left) <<> Ndef(right)  (sink reads \\in.ar(2))",
        "",
        "Constructor:",
        "  LPDisplaySigChain.new([\\outA, \\srcA])",
        "",
        "Key methods:",
        "  .rebuild()                   // ensure stereo, wire, play sink",
        "  .setTailSource(\\srcC)       // swap the final source and rebuild",
        "  .chainToString               // e.g., 'srcC → outA'",
        "  .symbols                     // copy of [sink, ..., source]",
        ""
    ];
    lines.do(_.postln);
    ^this
}

*apihelp {
    var lines;
    lines = [
        "LPDisplaySigChain.apihelp — quick recipes:",
        "  c = LPDisplaySigChain.new([\\outA, \\srcA]).rebuild;",
        "  c.setTailSource(\\srcC);",
        "  c.chainToString.postln;  // 'srcC → outA'",
        "",
        "Note: Ensure sinks read \\in.ar(2) and that sources produce stereo."
    ];
    lines.do(_.postln);
    ^this
}

*test {
    var srcKey, sinkKey, chain, okFlag;

    // Use single-backslash for Symbol literals:
    srcKey  = \_lpdisp_test_src;
    sinkKey = \_lpdisp_test_sink;

    okFlag  = true;

    Server.default.waitForBoot({
        // ephemeral test nodes
        Ndef(srcKey,  { PinkNoise.ar(0.02 ! 2) });  // quiet stereo
        Ndef(sinkKey, {
            var sig = \in.ar(2);
            // no SendPeakRMS here to keep test minimal
            sig
        });

        chain = this.new([sinkKey, srcKey]).rebuild;

        // brief run, then cleanup
        AppClock.sched(0.4, {
            var busOk;
            busOk = Ndef(sinkKey).bus.notNil and: { Ndef(sinkKey).isPlaying };
            if (busOk.not) { okFlag = false };

            Ndef(sinkKey).stop;
            Ndef(srcKey).clear(0.2);  // fade out

            ("LPDisplaySigChain.test: " ++ (okFlag.if("PASS", "FAIL"))).postln;
            nil
        });
    });
    ^this
}

}