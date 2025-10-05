// LivePedalboardSystem-AdapterBridge.sc
// v0.1.7
// MD 20251005-1122

/*
Purpose
- Builds on v0.1.6: still asserts CURRENT via setSourceCurrent + playCurrent,
  then adds a third, later pass to silence the NEXT chain at source explicitly.
- Also reaffirms 2-ch endpoints defensively on the last pass (non-intrusive).
Style
- var-first; lowercase names; no server.sync; no non-local '^' in callbacks.
*/

+ LivePedalboardSystem {
    installAdapterBridge {
        var commandManager, pedalboardRef, statusDisplayRef;
        var adapterAvailable, adapterPath;
        var postSwitchAudioGuard, silenceNextAtSource, reaffirmStereoEnds;

        commandManager = this.commandManager;
        pedalboardRef  = this.pedalboard;
        statusDisplayRef = this.statusDisplay;

        if(commandManager.isNil or: { pedalboardRef.isNil }) {
            "[LPS] installAdapterBridge: commandManager or pedalboard is nil; skipping.".warn;
            ^this;
        };

        // Ensure adapter exists (loads if needed)
        adapterAvailable = (~ct_applyOSCPathToMPB.notNil);
        if(adapterAvailable.not) {
            adapterPath = (Platform.userExtensionDir
                ++ "/LivePedalboardSuite/MagicPedalboard/adapter_CommandTree_to_MagicPedalboard.scd"
            ).standardizePath;
            if(File.exists(adapterPath)) {
                adapterPath.load;
                adapterAvailable = (~ct_applyOSCPathToMPB.notNil);
            };
        };
        if(adapterAvailable.not) {
            "[LPS] installAdapterBridge: adapter not found; keep existing queueExportCallback.".warn;
            ^this;
        };

        // -- helpers ----------------------------------------------------------
        silenceNextAtSource = { |currentSym = \A|
            var pb = pedalboardRef;
            var currentIsA, did;
            currentIsA = (currentSym == \A);
            did = false;

            // Prefer explicit per-chain setter for the inactive side
            if(currentIsA) {
                if(pb.respondsTo(\setSourceB)) { pb.setSourceB(\ts0); did = true };
            }{
                if(pb.respondsTo(\setSourceA)) { pb.setSourceA(\ts0); did = true };
            };

            // Fallback: exclusivity helper if present
            if(did.not and: { pb.respondsTo(\enforceExclusiveCurrentOptionA) }) {
                pb.enforceExclusiveCurrentOptionA(0.1);
                did = true;
            };

            ("[LPS] Ensured NEXT is silent ("
                ++ (currentIsA.if({ "B" }, { "A" })) ++ "→\\ts0, did=" ++ did ++ ")").postln;
            did
        };

        reaffirmStereoEnds = {
            // A gentle, idempotent nudge; no rewiring, just ensure 2-ch ar proxies exist.
            Server.default.bind({
                if(Ndef(\chainA).notNil) { Ndef(\chainA).ar(2) };
                if(Ndef(\chainB).notNil) { Ndef(\chainB).ar(2) };
            });
            "[LPS] Reaffirmed chain A/B as 2-ch endpoints.".postln;
            nil
        };

        // NEW v0.1.7: serialized ensure (3 passes: 120/240/360 ms)
        postSwitchAudioGuard = { |currentSym = \A|
            var doEnsure;
            doEnsure = { |attempt = 1|
                var delaySec;
                delaySec = switch(attempt, 1, { 0.12 }, 2, { 0.24 }, 3, { 0.36 }, { 0.36 });

                AppClock.sched(delaySec, {
                    var pb;
                    pb = pedalboardRef;

                    if(attempt == 1) {
                        // CURRENT-only reassert (same as v0.1.6)
                        if(pb.respondsTo(\setSourceCurrent)) { pb.setSourceCurrent(\testmelody) };
                        if(pb.respondsTo(\playCurrent))      { pb.playCurrent };
                        if(pb.respondsTo(\enforceExclusiveCurrentOptionA)) {
                            pb.enforceExclusiveCurrentOptionA(0.1);
                        };
                    };

                    if(attempt == 2) {
                        // repeat CURRENT-only reassert (race hardening)
                        if(pb.respondsTo(\setSourceCurrent)) { pb.setSourceCurrent(\testmelody) };
                        if(pb.respondsTo(\playCurrent))      { pb.playCurrent };
                    };

                    if(attempt == 3) {
                        // make NEXT silent explicitly (Option A), then nudge 2-ch ends
                        silenceNextAtSource.(currentSym);
                        reaffirmStereoEnds.();
                    };

                    ("[LPS] Post-switch ensure attempt #" ++ attempt
                        ++ " (CURRENT=" ++ currentSym.asString ++ ")").postln;

                    if(attempt < 3) { doEnsure.(attempt + 1) };
                    nil
                });
            };
            doEnsure.(1);
        };

        // Bridge: adapter + switch handling
        commandManager.queueExportCallback = { |canonicalPathString|
            var pathString, isSwitchPath, displayObj, currentSide;
            pathString = canonicalPathString.asString;

            ~ct_applyOSCPathToMPB.(pathString, pedalboardRef, statusDisplayRef);

            isSwitchPath = pathString.beginsWith("/switch");
            if(isSwitchPath) {
                if(~md_toggleCurrentChain.isKindOf(Function)) {
                    ~md_toggleCurrentChain.();
                }{
                    ~md_currentChain = ~md_currentChain ? \A;
                    ~md_currentChain = (~md_currentChain == \A).if({ \B }, { \A });
                };

                displayObj = commandManager.tryPerform(\display);
                if(displayObj.notNil) {
                    displayObj.tryPerform(\setActiveChainVisual, (~md_currentChain ? \A));
                };
                ("[LPS] ACTIVE chain toggled to " ++ (~md_currentChain ? \A).asString).postln;

                currentSide = (~md_currentChain ? \A);
                postSwitchAudioGuard.(currentSide);
            };
            nil
        };

        "[LPS] installAdapterBridge: adapter bridge active (v0.1.7).".postln;
        ^this
    }
}