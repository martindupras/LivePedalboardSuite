// LivePedalboardSystem.sc
// v0.4.1
// MD 20251009-1315


// misnamed. its just the starter, thats all. the other guys are the stystem. Oh well.
/* Purpose/Style
- Replace MagicDisplay call sites with LPDisplay controller + adapter.
- Open the window (must return -> a Window) and front it.
- Remove MagicDisplay.ensureMeterDefs; rely on SendPeakRMS taps in Ndefs.
*/

LivePedalboardSystem : Object {
	// idont think these instance variables are needed.
	// the objects should just talk to each other
	 // unless perhasp you want to shut them down neatly with a finalize.
	 // that might make sense
    var <> pedalboard;
    var <> pedalboardGUI; // no longer exists?
    var <> commandManager;
    var <> statusDisplay;      // DERIVED from lp display - not needed
	                           //will hold the LPDisplayAdapter (compat with CommandManager)
    var <> lpDisplay;          // LPDisplayLayoutWindow controller instance
    var <> logger;
    var <> treeFilePath;      // not used here as far as I can see - business of the tree anyway

	*new {
		^ super.new.init()
	}


	init{
		this.ensureServerReady;

		lpDisplay = LPDisplayLayoutWindow.new();// might be useful to send this 'this'
		                                        // as argument, so gui can close everhthing neatly
		                                        // while tsing & debugging? but no big deal.
		// logger = MDMiniLogger.new(lpDisplay);

		//Next  two instances created below should also have  logger as an argument to new

		commandManager = CommandManager.new(lpDisplay); // tree file path seems to be nil
		                                  /// should be done in the init of command manager
		pedalboard = MagicPedalboard.new(lpDisplay);

		// this.logger.info("LivePedalboardSystem", "System is ready.")
	}

      //================================================================================

     // this method should all be in the init of LPDisplayLayoutWindow
	// other objects can ask it  for their own refences its window obect
	// display adaptor smells atrocious. if any of it should survice, does not live here

    // Open and configure the LPDisplay window and return its Window object.
    // Also create an LPDisplayAdapter for CommandManager compatibility and set HUD/console options.
        bringUpLPDisplay { // canonical name: perform LPDisplay setup and return the Window
            var win;
            // Close legacy LPDisplay test windows as well
            this.closeExistingMagicDisplayWindows; //should be done by LPDisplay init
            //this.closeExistingLPDisplayWindows;

            // 1. Create the controller and open it -> returns a Window

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
            ^win // satisfy your "-> a Window" acceptance*/
        }

 cleanUp {
			// or close or stop,  if into the whole brevity thing
		    // pedalboard.cleanUp
		     // commandManager.cleanUp
		     this.closeExistingLPDisplayWindows;
		     // error manager.cleanUp
		     // maybe shut down server? (note sure order of that one)
	}



    // Backwards-compatible shim for callers that still use the old name.
   // bringUpMagicDisplayGUI { ^this.bringUpLPDisplay }

    // Boot the server (if needed), open the LPDisplay and create the pedalboard/command systems.
    // Installs adapter bridges, refreshes the initial display, and returns the display Window.

	 bringUpCommandSystem {
		// If anything here is actually doing anything,
		// it should be in the init for Command Manager
		// but it doesnt seem to do anything
        var klass, cm;

        // Find CommandManager class safely
        klass = \CommandManager.asClass;
        if (klass.isNil) {
            "[LPS] CommandManager class not found on classpath; skipping bringUpCommandSystem."
            .warn;
            ^this;
        };

        // Instantiate with the path already stored on this instance (nil ok; CM resolves internally)
        cm = klass.new(this.treeFilePath); // not needed here

        // Share the LPDisplay adapter so CM.display calls land in LPDisplay panes
        cm.display = this.statusDisplay; //not needed here

        // Minimal callback for now; AdapterBridge will overwrite this later
        cm.queueExportCallback = { |path|     // dear ghod not needed here
            ("[LPS] queued path: " ++ path.asString).postln;
        };

        this.commandManager = cm; // belongs in command manager ffs
        "[LPS] CommandManager initialized (bridge pending).".postln;
        ^this
    }




	bringUpAll {  /// amy of this that is needed needs moving
        var didBoot, win;
        didBoot = this.ensureServerReady;
        win = this.bringUpMagicDisplayGUI; // returns -> a Window
        this.bringUpPedalboard;
        this.bringUpCommandSystem;

        // Install the CommandTree->MthePedalboard bridge and auto meters (LPDisplay-visible taps)
		this.installAdapterBridge; //"where is this method?
		                          // Definitely No this code should be in display

        //this.enableAutoMeters(24, 0.35);

        // Initial snapshot to the display (chains + active side + status)
        this.refreshDisplay;

		this.ensureLogger; // where is this method?
		this.logInfo("LivePedalboardSystem", "System is ready.");
        //logger.info("LivePedalboardSystem", "✅ System is ready.");
        ^win
    }

	// This should be in the init for MagicPedalboard

    // Construct and initialize the MagicPedalboard (if available), wiring the LPDisplay adapter when present.
    // Stores the new pedalboard on the system and returns the system instance for chaining.

	bringUpPedalboard {
        var klass, thePedalboard;

        // Find MagicPedalboard class defensively
        klass = \MagicPedalboard.asClass;
        if(klass.isNil) {
            "[LPS] MagicPedalboard class not found on classpath; skipping bringUpPedalboard."
            .warn;
            ^this;
        };

        // Construct, optionally wiring the display adapter if we have one
        thePedalboard = if(this.statusDisplay.notNil) {
            klass.new(this.statusDisplay)
        } {
            klass.new
        };

        if(this.statusDisplay.notNil and: { thePedalboard.respondsTo(\setDisplay) }) {
            thePedalboard.setDisplay(this.statusDisplay);
        };

        this.pedalboard = thePedalboard;       // store reference
        this.pedalboardGUI = nil;   // no runner GUI in the LPDisplay path

        " [LPS] MagicPedalboard initialized and bound to LPDisplay adapter."
        .postln;

        ^this
    }

    // Update the LPDisplay (via the adapter) with the current pedalboard state.
    // Safely queries the pedalboard for chain symbols and active side, then updates visuals and a short status.
    refreshDisplay {
		//this is crazy - sounds like something the pedal board should do on an init or a test
		// does gui need human control eg test?
		// that might be a reson to have some of this method herebut unconvinces

		var aSyms, bSyms, active;
        var adapter;
        adapter = statusDisplay; // LPDisplayAdapter
        if(adapter.isNil) { ^this };

        // Attempt to fetch chain symbol arrays from MagicPedalboard if available
        aSyms = pedalboard.tryPerform(\chainSymbolsA);
		             // why not just make sure they do understand it?
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
		// looks like it could be made simpler
        var s;
        s = Server.default;
        if (s.serverRunning.not) {
            s.boot;
            s.waitForBoot; // allowed in your safe-reset pattern
            Server.default.bind({
                s.initTree;
                s.defaultGroup.freeAll;
            });
        };

        ^ this
    }

// Back-compat entry point (your bringUp path is calling this)
    closeExistingMagicDisplayWindows {  //why on earth do we need this who calls it??
        this.closeExistingLPDisplayWindows; // though can be worth having to get a nice name
		                                   // though duplication can casue problems
        ^this
    }

    // Canonical closer: match ONLY LPDisplay windows
    closeExistingLPDisplayWindows {
        var windowsToClose;

        windowsToClose = Window.allWindows.select {arg w;
            var nameString;
            nameString = (w.name ? "").asString; // checks if Nil
            (nameString.beginsWith("LPDisplay")) and: { w.isClosed.not }
            };

        windowsToClose.do({ arg w;
            if (w.notNil and: { w.isClosed.not }) {
                // avoid recursion if the window has onClose hooks
                w.close;
            };
        });

        ^this
    }
}