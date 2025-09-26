// LivePedalboardSystem-AdapterBridge.sc
// v0.1.1
// MD 2025-09-26 15:22 BST

/* Purpose
   Install a queueExportCallback that routes SHORT canonical commands
   (e.g., "/add/delay") through your adapter (~ct_applyOSCPathToMPB),
   so they apply to MagicPedalboardNew safely.
   Additionally, if the path starts with "/switch", toggle the HUD's
   current-chain flag so the ACTIVE tint stays solid (no pulsing).

   Style
   - var-first; descriptive variable names; no server.sync; no non-local '^'.
   - Safe no-op if adapter or references are missing.
*/

+ LivePedalboardSystem {

  installAdapterBridge {
    var commandManager, pedalboardRef, statusDisplayRef;
    var adapterAvailable, adapterPath;

    commandManager    = this.commandManager;
    pedalboardRef     = this.pedalboard;
    statusDisplayRef  = this.statusDisplay;

    if(commandManager.isNil or: { pedalboardRef.isNil }) {
      "[LPS] installAdapterBridge: commandManager or pedalboard is nil; skipping.".warn;
      ^this;
    };

    // Ensure the adapter function is available
    adapterAvailable = (~ct_applyOSCPathToMPB.notNil);
    if(adapterAvailable.not) {
      adapterPath = (Platform.userExtensionDir
        ++ "/LivePedalboardSuite/MagicPedalboard/adapter_CommandTree_to_MagicPedalboard.scd").standardizePath;
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
      var pathString, isSwitchPath;

      pathString = canonicalPathString.asString;
      ~ct_applyOSCPathToMPB.(pathString, pedalboardRef, statusDisplayRef);

      // ACTIVE chain rule: if the canonical path starts with "/switch", toggle A/B
      // Known-good assumption: "/switch" is a toggle between A and B.
      isSwitchPath = pathString.beginsWith("/switch");
      if(isSwitchPath) {
        // Use the tiny helper defined in MagicDisplayGUI_PerfHUD_ActiveChain_Ext.scd
        if(~md_toggleCurrentChain.isKindOf(Function)) {
          ~md_toggleCurrentChain.();
        }{
          // Fallback: initialize to A if helper is missing
          ~md_currentChain = ~md_currentChain ? \A;
          ~md_currentChain = (~md_currentChain == \A).if({ \B }, { \A });
        };
        ("[LPS] ACTIVE chain toggled to " ++ (~md_currentChain ? \A).asString).postln;
      };

      nil  // explicit nil return, no non-local '^'
    };

    "[LPS] installAdapterBridge: adapter bridge active.".postln;
    ^this
  }

}
