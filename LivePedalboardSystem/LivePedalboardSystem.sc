// LivePedalboardSystem.sc
// v0.3.2.2
// MD 20251009-1315

/* Purpose/Style
- Replace MagicDisplay call sites with LPDisplay controller + adapter.
- Open the window (must return -> a Window) and front it.
- Remove MagicDisplay.ensureMeterDefs; rely on SendPeakRMS taps in Ndefs.
*/

LivePedalboardSystem : Object {
    var <> pedalboard;
    var <> pedalboardGUI;
    var <> commandManager;
    var <> statusDisplay;      // will hold the LPDisplayAdapter (compat with CommandManager)
    var <> lpDisplay;          // LPDisplayLayoutWindow controller instance
    var <> logger;
    var <> treeFilePath;

    // Open and configure the LPDisplay window and return its Window object.
    // Also create an LPDisplayAdapter for CommandManager compatibility and set HUD/console options.
        bringUpLPDisplay { // canonical name: perform LPDisplay setup and return the Window
            var win;
            // Close legacy LPDisplay test windows as well
            this.closeExistingMagicDisplayWindows; // keeps your existing filter
            //this.closeExistingLPDisplayWindows;

            // 1. Create the controller and open it -> returns a Window
            lpDisplay = LPDisplayLayoutWindow.new;
            win = lpDisplay.open; // -> a Window
            // 2. Create an adapter so CommandManager.display calls still work
            statusDisplay = LPDisplayAdapter.new(lpDisplay);
            // 3. Optional HUD mapping + console quiet
            lpDisplay.setHudMap(LPDisplayHudMap.new(-6, -60, 1.0));
            lpDisplay.setConsoleLevelsOn(false);
            // 4. Front the window and share display with CM (if any)
            AppClock.sched(0.0, { win.front; nil });
            if(commandManager.respondsTo(\display_)) { commandManager.display = statusDisplay };
            // 5. No MagicDisplay.ensureMeterDefs anymore (taps live in Ndefs)
            ^win // satisfy your "-> a Window" acceptance
        }


    // Backwards-compatible shim for callers that still use the old name.
    bringUpMagicDisplayGUI { ^this.bringUpLPDisplay }

    // Boot the server (if needed), open the LPDisplay and create the pedalboard/command systems.
    // Installs adapter bridges, refreshes the initial display, and returns the display Window.
    bringUpAll {
        var didBoot, win;
        didBoot = this.ensureServerReady;
        win = this.bringUpMagicDisplayGUI; // returns -> a Window
        this.bringUpPedalboard;
        this.bringUpCommandSystem;

        // Install the CommandTree->MPB bridge and auto meters (LPDisplay-visible taps)
        this.installAdapterBridge;
        //this.enableAutoMeters(24, 0.35);

        // Initial snapshot to the display (chains + active side + status)
        this.refreshDisplay;

		this.ensureLogger;
		this.logInfo("LivePedalboardSystem", "System is ready.");
        //logger.info("LivePedalboardSystem", "✅ System is ready.");
        ^win
    }

bringUpPedalboard {
        var klass, pb;

        // Find MagicPedalboard class defensively
        klass = \MagicPedalboard.asClass;
        if(klass.isNil) {
            "[LPS] MagicPedalboard class not found on classpath; skipping bringUpPedalboard."
            .warn;
            ^this;
        };

        // Construct, optionally wiring the display adapter if we have one
        pb = if(this.statusDisplay.notNil) {
            klass.new(this.statusDisplay)
        } {
            klass.new
        };

        if(this.statusDisplay.notNil and: { pb.respondsTo(\setDisplay) }) {
            pb.setDisplay(this.statusDisplay);
        };

        this.pedalboard = pb;       // store reference
        this.pedalboardGUI = nil;   // no runner GUI in the LPDisplay path

        " [LPS] MagicPedalboard initialized and bound to LPDisplay adapter."
        .postln;

        ^this
    }

    // Update the LPDisplay (via the adapter) with the current pedalboard state.
    // Safely queries the pedalboard for chain symbols and active side, then updates visuals and a short status.
    refreshDisplay {
        var aSyms, bSyms, active;
        var adapter;
        adapter = statusDisplay; // LPDisplayAdapter
        if(adapter.isNil) { ^this };

        // Attempt to fetch chain symbol arrays from MagicPedalboard if available
        aSyms = pedalboard.tryPerform(\chainSymbolsA);
        bSyms = pedalboard.tryPerform(\chainSymbolsB);
        // fallbacks to keep it safe; show sinks if nothing else
        aSyms = aSyms ? [\chainA, \… , \sourceA];
        bSyms = bSyms ? [\chainB, \… , \sourceB];

        adapter.tryPerform(\setChains, aSyms, bSyms);

        active = pedalboard.tryPerform(\currentKey) ? \A; // expect \A or \B
        adapter.tryPerform(\setActiveChainVisual, active);

        adapter.tryPerform(\showExpectation, "READY", 0);
        ^this
    }

    ensureServerReady {
        var s, didBoot;
        s = Server.default;
        didBoot = false;

        if (s.serverRunning.not) {
            s.boot;
            s.waitForBoot; // allowed in your safe-reset pattern
            didBoot = true;
        };

        if (didBoot) {
            Server.default.bind({
                s.initTree;
                s.defaultGroup.freeAll;
            });
        };

        ^didBoot
    }

// Back-compat entry point (your bringUp path is calling this)
    closeExistingMagicDisplayWindows {
        var selfRef;
        selfRef = this;
        selfRef.closeExistingLPDisplayWindows;
        ^selfRef
    }

    // Canonical closer: match ONLY LPDisplay windows
    closeExistingLPDisplayWindows {
        var windowsToClose, shouldClose;

        shouldClose = { arg w;
            var nameString;
            nameString = (w.name ? "").asString;
            (nameString.beginsWith("LPDisplay")) and: { w.isClosed.not }
        };

        windowsToClose = Window.allWindows.select(shouldClose);

        windowsToClose.do({ arg w;
            var wref;
            wref = w;
            if (wref.notNil and: { wref.isClosed.not }) {
                // avoid recursion if the window has onClose hooks
                wref.onClose = { };
                wref.close;
            };
        });

        ^this
    }

}