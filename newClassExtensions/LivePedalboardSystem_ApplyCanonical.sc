// LivePedalboardSystem_ApplyCanonical.sc
// v1.1 — add applyCanonicalPath (adapter shim) mapping canonical verbs to pedalboard
// MD 2025-10-02

+ LivePedalboardSystem {

    applyCanonicalPath { |shortPath|
        var pedalboardRef, parts, verbSymbol, argSymbol, applied, switchCandidates;

        pedalboardRef = this.tryPerform(\pedalboard);
        parts         = shortPath.asString.split($/).reject({ |s| s.size == 0 });
        applied       = false;

        if (pedalboardRef.notNil and: { parts.size > 0 }) {
            verbSymbol = parts[0].asSymbol;
            argSymbol  = (parts.size > 1).if({ parts[1].asSymbol }, { nil });

            switch(verbSymbol,
                \add, {
                    if (pedalboardRef.respondsTo(\add) and: { argSymbol.notNil }) {
                        pedalboardRef.add(argSymbol); applied = true;
                    };
                },
                \setSource, {
                    if (pedalboardRef.respondsTo(\setSource) and: { argSymbol.notNil }) {
                        pedalboardRef.setSource(argSymbol); applied = true;
                    };
                },
                \bypass, {
                    if (pedalboardRef.respondsTo(\bypass) and: { argSymbol.notNil }) {
                        pedalboardRef.bypass(argSymbol); applied = true;
                    };
                },
                \clear, {
                    if (pedalboardRef.respondsTo(\clear)) {
                        pedalboardRef.clear; applied = true;
                    };
                },
                \switch, {
                    // Try likely names; keep this list small and explicit.
                    switchCandidates = [ \switchChain, \switchChains, \toggleAB, \toggleChain, \nextChain ];
                    switchCandidates.do({ |selectorSym|
                        if (applied.not and: { pedalboardRef.respondsTo(selectorSym) }) {
                            pedalboardRef.perform(selectorSym);
                            applied = true;
                        };
                    });
                },
                { } // default — do nothing
            );
        };

        (applied.if({
            ("[LPS] applyCanonicalPath applied: " ++ shortPath).postln;
        },{
            ("[LPS] applyCanonicalPath could not apply: " ++ shortPath).warn;
        }));

        applied
    }
}