// LivePedalboardSystem-BringUpCommandSystem.sc
// v0.1.0
// MD 20251006-1502

/* Purpose
   - Provide bringUpCommandSystem for the currently loaded LivePedalboardSystem.
   Style
   - var-first; lowercase names; no server.sync; defensive checks; no non-local returns.
*/

+ LivePedalboardSystem {

    bringUpCommandSystem {
        var klass, cm;

        // Find CommandManager class safely
        klass = \CommandManager.asClass;
        if (klass.isNil) {
            "[LPS] CommandManager class not found on classpath; skipping bringUpCommandSystem."
            .warn;
            ^this;
        };

        // Instantiate with the path already stored on this instance (nil ok; CM resolves internally)
        cm = klass.new(this.treeFilePath);

        // Share the LPDisplay adapter so CM.display calls land in LPDisplay panes
        cm.display = this.statusDisplay;

        // Minimal callback for now; AdapterBridge will overwrite this later
        cm.queueExportCallback = { |path|
            ("[LPS] queued path: " ++ path.asString).postln;
        };

        this.commandManager = cm;
        "[LPS] CommandManager initialized (bridge pending).".postln;
        ^this
    }
}
