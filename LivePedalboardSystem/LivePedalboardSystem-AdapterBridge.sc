// LivePedalboardSystem-AdapterBridge.sc
// v0.1.5-displayOnly
// MD 20251005-1633

/*
Purpose
- DISPLAY-ONLY bridge:
  • Forward canonical paths from CommandManager to MagicPedalboard via adapter.
  • Update LPDisplay ACTIVE/NEXT on "/switch".
- No audio "ensure", no source fiddling, no exclusivity enforcement here.
Style
- var-first; lowercase names; no server.sync; AppClock for UI only; no non-local returns.
*/

+ LivePedalboardSystem {
    installAdapterBridge {
        var commandManager, pedalboardRef, statusDisplayRef;
        var adapterAvailable, adapterPath;

        commandManager   = this.commandManager;
        pedalboardRef    = this.pedalboard;
        statusDisplayRef = this.statusDisplay;

        if(commandManager.isNil or: { pedalboardRef.isNil }) {
            "[LPS] installAdapterBridge (display-only): commandManager or pedalboard is nil; skipping.".warn;
            ^this;
        };

        // ensure the CommandTree -> MagicPedalboard adapter function exists
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
            "[LPS] installAdapterBridge (display-only): adapter not found; keeping existing queueExportCallback.".warn;
            ^this;
        };

        commandManager.queueExportCallback = { |canonicalPathString|
            var pathString, isSwitchPath, displayObj;

            pathString = canonicalPathString.asString;

            // 1) apply to MPB via adapter
            ~ct_applyOSCPathToMPB.(pathString, pedalboardRef, statusDisplayRef);

            // 2) if "/switch", flip ACTIVE/NEXT visual only (no audio actions)
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
                ("[LPS] ACTIVE chain toggled to " ++ (~md_currentChain ? \A).asString
                ++ " (display-only)").postln;
            };
            nil
        };

        "[LPS] installAdapterBridge: display-only bridge active (v0.1.5-displayOnly).".postln;
        ^this
    }
}