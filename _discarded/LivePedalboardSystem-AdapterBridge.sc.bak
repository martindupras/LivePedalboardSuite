// LivePedalboardSystem-AdapterBridge.sc
// v0.1.0
// MD 20250923-1324

/* Purpose
   Install a queueExportCallback that routes SHORT canonical commands
   (e.g., "/add/delay") through your adapter (~ct_applyOSCPathToMPB),
   so they apply to MagicPedalboardNew safely.

   Style
   - var-first; descriptive variable names; no server.sync.
   - Class extension only; safe no-op if adapter or references are missing.
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
        ++ "/LivePedalboardSuite/Magicpedalboard/adapter_CommandTree_to_MagicPedalboard.scd").standardizePath;
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
      ~ct_applyOSCPathToMPB.(canonicalPathString, pedalboardRef, statusDisplayRef);
    };

    "[LPS] installAdapterBridge: adapter bridge active.".postln;
    ^this;
  }

}

