// LivePedalboardSystem-AdapterBridge.sc
// v0.1.6
// MD 20251005-1030

/*
Purpose
- Same bridge as v0.1.5, but with a serialized post-switch ensure that avoids
  per-chain setters and only asserts CURRENT via setSourceCurrent + playCurrent.
- Two retries: ~120 ms and ~240 ms after the adapter applies "/switch".
Style
- var-first; lowercase names; no server.sync; no non-local '^' in callbacks.
*/

+ LivePedalboardSystem {
    installAdapterBridge {
        var commandManager, pedalboardRef, statusDisplayRef;
        var adapterAvailable, adapterPath;
        var postSwitchAudioGuard;

        commandManager = this.commandManager;
        pedalboardRef  = this.pedalboard;
        statusDisplayRef = this.statusDisplay;

        if(commandManager.isNil or: { pedalboardRef.isNil }) {
            "[LPS] installAdapterBridge: commandManager or pedalboard is nil; skipping.".warn;
            ^this;
        };

        // Ensure the adapter function is available (loads if needed)
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

        // NEW v0.1.6: serialized ensure using CURRENT-only setters (two attempts)
        postSwitchAudioGuard = { |currentSym = \A|
            var doEnsure;
            doEnsure = { |attempt = 1|
                var delaySec;
                delaySec = (attempt == 1).if({ 0.12 }, { 0.24 }); // 120 ms, then 240 ms
                AppClock.sched(delaySec, {
                    var pb;
                    pb = pedalboardRef;
                    // CURRENT-only reassert
                    if(pb.respondsTo(\setSourceCurrent)) { pb.setSourceCurrent(\testmelody) };
                    if(pb.respondsTo(\playCurrent))      { pb.playCurrent };
                    // optional exclusivity (Option A)
                    if(pb.respondsTo(\enforceExclusiveCurrentOptionA)) {
                        pb.enforceExclusiveCurrentOptionA(0.1);
                    };
                    ("[LPS] Post-switch ensure attempt #" ++ attempt
                        ++ " (CURRENT=" ++ currentSym.asString ++ ")").postln;

                    // run second attempt once
                    if(attempt < 2) { doEnsure.(attempt + 1) };

                    nil
                });
            };
            doEnsure.(1);
        };

        // Bridge: apply canonical path via adapter and handle "/switch"
        commandManager.queueExportCallback = { |canonicalPathString|
            var pathString, isSwitchPath, displayObj, currentSide;
            pathString = canonicalPathString.asString;

            // Apply to MPB via adapter
            ~ct_applyOSCPathToMPB.(pathString, pedalboardRef, statusDisplayRef);

            // Detect "/switch" and flip ACTIVE/NEXT visuals
            isSwitchPath = pathString.beginsWith("/switch");
            if(isSwitchPath) {
                if(~md_toggleCurrentChain.isKindOf(Function)) {
                    ~md_toggleCurrentChain.();
                }{
                    ~md_currentChain = ~md_currentChain ? \A;
                    ~md_currentChain = (~md_currentChain == \A).if({ \B }, { \A });
                };

                // Notify LPDisplay via LPDisplayAdapter on CommandManager.display
                displayObj = commandManager.tryPerform(\display);
                if(displayObj.notNil) {
                    displayObj.tryPerform(\setActiveChainVisual, (~md_currentChain ? \A));
                };
                ("[LPS] ACTIVE chain toggled to " ++ (~md_currentChain ? \A).asString).postln;

                // CURRENT-only ensure (two retries)
                currentSide = (~md_currentChain ? \A);
                postSwitchAudioGuard.(currentSide);
            };
            nil  // explicit; no non-local return from callback
        };

        "[LPS] installAdapterBridge: adapter bridge active (v0.1.6).".postln;
        ^this
    }
}