// LivePedalboardSystem-AdapterBridge.sc
// v0.1.3
// MD 2025-10-04 17:58 BST

/*
Purpose
- Install a queueExportCallback that applies SHORT canonical commands ("/add/…", "/switch", "/setSource/…")
  to MagicPedalboard via ~ct_applyOSCPathToMPB.
- On "/switch", flip the ACTIVE/NEXT visual in LPDisplay by calling
  commandManager.display.tryPerform(\setActiveChainVisual, …) on the adapter.

Style
- var-first; lowercase names; no server.sync; no non-local '^' from inside callbacks.
*/

+ LivePedalboardSystem {

    installAdapterBridge {
        var commandManager, pedalboardRef, statusDisplayRef;
        var adapterAvailable, adapterPath;

        commandManager   = this.commandManager;
        pedalboardRef    = this.pedalboard;
        statusDisplayRef = this.statusDisplay; // left for possible future use; not used for ACTIVE/NEXT

        if(commandManager.isNil or: { pedalboardRef.isNil }) {
            "[LPS] installAdapterBridge: commandManager or pedalboard is nil; skipping.".warn;
            ^this;
        };

        // Ensure the adapter function is available
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

        // Bridge: every queued canonical path is applied via the adapter
        commandManager.queueExportCallback = { |canonicalPathString|
            var pathString, isSwitchPath, displayObj;

            pathString = canonicalPathString.asString;

            // Apply to MPB via adapter
            ~ct_applyOSCPathToMPB.(pathString, pedalboardRef, statusDisplayRef);

            // ACTIVE chain rule: if canonical path starts with "/switch", toggle A/B and update LPDisplay (via adapter)
            isSwitchPath = pathString.beginsWith("/switch");
            if(isSwitchPath) {
                // toggle shared state
                if(~md_toggleCurrentChain.isKindOf(Function)) {
                    ~md_toggleCurrentChain.();
                }{
                    ~md_currentChain = ~md_currentChain ? \A;
                    ~md_currentChain = (~md_currentChain == \A).if({ \B }, { \A });
                };

                // Use the CommandManager.display (LPDisplayAdapter) to forward the visual to LPDisplayLayoutWindow
                displayObj = commandManager.tryPerform(\display);
                if(displayObj.notNil) {
                    displayObj.tryPerform(\setActiveChainVisual, (~md_currentChain ? \A));
                };

                ("[LPS] ACTIVE chain toggled to " ++ (~md_currentChain ? \A).asString).postln;
            };

            nil // explicit nil return; no non-local '^'
        };

        "[LPS] installAdapterBridge: adapter bridge active.".postln;
        ^this
    }
}