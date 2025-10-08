// LivePedalboardSystem.sc
// v0.3.1
// MD 20251006-1310

/* Purpose/Style
- Replace MagicDisplay call sites with LPDisplay controller + adapter.
- Open the window (must return -> a Window) and front it.
- Remove MagicDisplay.ensureMeterDefs; rely on SendPeakRMS taps in Ndefs.
*/

LivePedalboardSystem : Object {
    var <>pedalboard;
    var <>pedalboardGUI;
    var <>commandManager;
    var <>statusDisplay;      // will hold the LPDisplayAdapter (compat with CommandManager)
    var <>lpDisplay;          // LPDisplayLayoutWindow controller instance
    var <>logger;
    var <>treeFilePath;

    bringUpMagicDisplayGUI { // keep name for now (compat), but do LPDisplay work
        var win;
        // Close legacy LPDisplay test windows as well
        this.closeExistingMagicDisplayWindows; // keeps your existing filter
        // 1) Create the controller and open it -> returns a Window
        lpDisplay = LPDisplayLayoutWindow.new;
        win = lpDisplay.open; // -> a Window
        // 2) Create an adapter so CommandManager.display calls still work
        statusDisplay = LPDisplayAdapter.new(lpDisplay);
        // 3) Optional HUD mapping + console quiet
        lpDisplay.setHudMap(LPDisplayHudMap.new(-6, -60, 1.0));
        lpDisplay.setConsoleLevelsOn(false);
        // 4) Front the window and share display with CM (if any)
        AppClock.sched(0.0, { win.front; nil });
        if(commandManager.respondsTo(\display_)) { commandManager.display = statusDisplay };
        // 5) No MagicDisplay.ensureMeterDefs anymore (taps live in Ndefs)
        ^win // satisfy your "-> a Window" acceptance
    }

    bringUpAll {
        var didBoot, win;
        didBoot = this.ensureServerReady;
        win = this.bringUpMagicDisplayGUI; // returns -> a Window
        this.bringUpPedalboard;
        this.bringUpCommandSystem;

        // Install the CommandTree->MPB bridge and auto meters (LPDisplay-visible taps)
        this.installAdapterBridge;
        this.enableAutoMeters(24, 0.35);

        // Initial snapshot to the display (chains + active side + status)
        this.refreshDisplay;

		this.ensureLogger;
		this.logInfo("LivePedalboardSystem", "System is ready.");
        //logger.info("LivePedalboardSystem", "✅ System is ready.");
        ^win
    }

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
}