// LivePedalboardSystem.sc
// v0.2.8
// MD 2025-09-22 1204

// Purpose: Bring-up MagicPedalboard + CommandManager + single MagicDisplayGUI (no duplicate windows).
// Style: var-first, logger-enabled, AppClock-safe, Server.default.bind for server ops, no server.sync.

LivePedalboardSystem : Object {
	var <>pedalboard;
	var <>pedalboardGUI;
	var <>commandManager;
	var <>statusDisplay;   // this will hold a MagicDisplayGUI
	var <>logger;
	var <>treeFilePath;

	*new { arg treePath;
		^super.new.init(treePath);
	}

	init { arg treePath;
		var defaultPath;
		logger = MDMiniLogger.get;

		// Minimal change: use LivePedalboardSuite (symlinked in Extensions) as canonical default
		defaultPath = Platform.userExtensionDir
		++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";

		treeFilePath = treePath.ifNil { defaultPath };
		^this;
	}


	bringUpAll {
		// ✅ Make sure the server is up and the tree is clean *before* we create MPB
		this.ensureServerReady;

		this.bringUpMagicDisplayGUI;   // 1) GUI first
		this.bringUpPedalboard;        // 2) create MPB (it will create groups)
		this.bringUpCommandSystem;     // 3) hook command system
		this.ensureAudioOn;            // 4) prime sources + play current (no tree reset here)


		// meters last (you already moved this)
/*    if(statusDisplay.notNil and: { statusDisplay.respondsTo(\enableMeters) }) {
        statusDisplay.enableMeters(true);
    };*/

		//v0.2.8
		AppClock.sched(0.35, {    // 350 ms is enough to outlive the initial MPB rebuild
			if(statusDisplay.notNil and: { statusDisplay.respondsTo(\enableMeters) }) {
				statusDisplay.enableMeters(true);
			};
			nil
		});

		logger.info("LivePedalboardSystem", "✅ System is ready.");
		^this;
	}


/*	bringUpPedalboard {
		pedalboard = MagicPedalboard.new;
		pedalboardGUI = MagicPedalboardTestRunner.new(pedalboard, nil);
		pedalboardGUI.bringUp;
		logger.info("Pedalboard", "Pedalboard and GUI initialized.");
	}*/

/*	bringUpPedalboard {
		// new pedalboard bound to display (if ctor supports it)
		pedalboard = if (statusDisplay.notNil) {
			MagicPedalboardNew.new(statusDisplay)
		} {
			MagicPedalboardNew.new
		};

		// be defensive: wire after construction too, if there is a setter
		if (statusDisplay.notNil and: { pedalboard.respondsTo(\setDisplay) }) {
			pedalboard.setDisplay(statusDisplay);
		};

		// remove runner usage; it's not needed for the new GUI path
		pedalboardGUI = nil;

		logger.info("Pedalboard", "MagicPedalboardNew initialized and bound to display.");
	}*/

	bringUpPedalboard {
		// new pedalboard bound to display (if ctor supports it)
		pedalboard = if (statusDisplay.notNil) {
			MagicPedalboardNew.new(statusDisplay)
		} {
			MagicPedalboardNew.new
		};

		// be defensive: wire after construction too, if there is a setter
		if (statusDisplay.notNil and: { pedalboard.respondsTo(\setDisplay) }) {
			pedalboard.setDisplay(statusDisplay);
		};

		// remove runner usage; it's not needed for the new GUI path
		pedalboardGUI = nil;

		logger.info("Pedalboard", "MagicPedalboardNew initialized and bound to display.");
	}

	bringUpCommandSystem {
		commandManager = CommandManager.new(treeFilePath);


		// inject GUI so updateDisplay() can actually update something
		commandManager.display = statusDisplay;

		// Queue export -> pedalboard
		commandManager.queueExportCallback = { |oscPath|
			pedalboard.handleCommand(oscPath);
			logger.info("Integration", "Sent command to pedalboard: " ++ oscPath);
			// If GUI is up, show last command
			if (statusDisplay.notNil and: { statusDisplay.respondsTo(\showExpectation) }) {
				statusDisplay.showExpectation("Sent: " ++ oscPath, 0);
			};
		};

		logger.info("CommandSystem", "CommandManager initialized and connected.");
	}

	// --- Single MagicDisplayGUI window, with meters enabled ---
/*	bringUpMagicDisplayGUI {
		// Create your existing MagicDisplayGUI (no "openUnique" in your class)
		statusDisplay = MagicDisplayGUI.new;  // constructor signature matches your file
		// Set initial text using your API: showExpectation(...)
		statusDisplay.showExpectation("System ready.", 0);  // MagicDisplayGUI has no updateStatus
		// Share GUI with CommandManager so CommandManager:setStatus can target it
		if (commandManager.respondsTo(\display_)) { commandManager.display = statusDisplay; };

		// Ensure meter SynthDefs are present before enabling
		this.ensureMeterDefs;
		statusDisplay.enableMeters(true);
	}*/

/*	bringUpMagicDisplayGUI {
		statusDisplay = MagicDisplayGUI_GridDemo.new;    // ← newer layout
		statusDisplay.showExpectation("System ready.", 0);

		// share GUI with CommandManager so CommandManager:setStatus can target it
		if (commandManager.respondsTo(\display_)) { commandManager.display = statusDisplay; };

		this.ensureMeterDefs;
		statusDisplay.enableMeters(true);
	}*/
	bringUpMagicDisplayGUI {
		statusDisplay = MagicDisplayGUI_GridDemo.new;    // ← newer layout
		statusDisplay.showExpectation("System ready.", 0);

		// share GUI with CommandManager so CommandManager:setStatus can target it
		if (commandManager.respondsTo(\display_)) { commandManager.display = statusDisplay; };

		this.ensureMeterDefs;
		//statusDisplay.enableMeters(true);
	}


	// --- Provide \busMeterA / \busMeterB if they don't exist yet ---
	// replaced with the below, which uses MagicDisplay meters instead:
	ensureMeterDefs {
		MagicDisplay.ensureMeterDefs(2); // or MagicDisplay.setMeterChannels(2)
	}

	// --- Conservative "make sure something is audible" ---
/*	ensureAudioOn {
		var started;
		started = false;

		if (pedalboard.respondsTo(\start)) { pedalboard.start; started = true; }
		{ if (pedalboard.respondsTo(\play)) { pedalboard.play; started = true; } };

		if (started.not) {
			this.tryPlayNdefs([\chainA, \chainB, \testmelody]);
		};

		logger.info("Audio", "ensureAudioOn called (started: %).".format(started));
	}*/


	ensureAudioOn {
		var s;
		s = Server.default;

		// Define sources/sinks idempotently
		Server.default.bind({
			if (Ndef(\testmelody).source.isNil) {
				Ndef(\testmelody, {
					var trig = Impulse.kr(3.2);
					var seq = Dseq([220,277.18,329.63,392,329.63,277.18,246.94], inf);
					var f = Demand.kr(trig, 0, seq);
					var env = Decay2.kr(trig, 0.01, 0.35);
					var pan = ToggleFF.kr(trig).linlin(0,1,-0.6,0.6);
					Pan2.ar(SinOsc.ar(f) * env * 0.25, pan)
				});
			};
			Ndef(\testmelody).ar(2);

			if (Ndef(\ts0).source.isNil) { Ndef(\ts0, { Silent.ar(2) }) };
			Ndef(\ts0).ar(2);

			// Ensure sink proxies exist at audio rate; MPB wires them
			Ndef(\chainA).ar(2);
			Ndef(\chainB).ar(2);
		});

		// Route CURRENT to \testmelody + Option A
		if (pedalboard.respondsTo(\setSourceCurrent)) {
			pedalboard.setSourceCurrent(\testmelody);
		};
		if (pedalboard.respondsTo(\enforceExclusiveCurrentOptionA)) {
			pedalboard.enforceExclusiveCurrentOptionA(0.1);
		};

		// Make sure CURRENT sink is actually playing; stop the other
		if (pedalboard.respondsTo(\playCurrent)) {
			pedalboard.playCurrent;
		} {
			Server.default.bind({
				if (Ndef(\chainA).isPlaying.not) { Ndef(\chainA).play(numChannels: 2) };
				if (Ndef(\chainB).isPlaying)     { Ndef(\chainB).stop };
			});
		};

		// One tiny deferred re-assert (survives any late rebuild)
/*		AppClock.sched(0.10, {
        if (pedalboard.respondsTo(\playCurrent)) {
            pedalboard.playCurrent;
        } {
            Server.default.bind({
                if (Ndef(\chainA).isPlaying.not) { Ndef(\chainA).play(numChannels: 2) };
                if (Ndef(\chainB).isPlaying)     { Ndef(\chainB).stop };
            });
        };
        nil*/


		// --- Make sure CURRENT sink is actually playing (single deferred assert) ---
		AppClock.sched(0.25, {     // allow the temp SynthDef add to complete
			if (pedalboard.respondsTo(\playCurrent)) {
				pedalboard.playCurrent;  // MPB decides which (A/B) should be audible
			} {
				Server.default.bind({
					if (Ndef(\chainA).isPlaying.not) { Ndef(\chainA).play(numChannels: 2) };
					if (Ndef(\chainB).isPlaying)     { Ndef(\chainB).stop };
				});
			};
			nil
		});



		if (pedalboard.respondsTo(\printChains)) { pedalboard.printChains };
		logger.info("Audio", "Primed CURRENT with \\testmelody; ensured CURRENT is playing (Option A).");
	}


	ensureServerReady {
		var s, didBoot;

		s = Server.default;
		didBoot = false;

		if (s.serverRunning.not) {
			s.boot;
			s.waitForBoot;   // permitted in your safe-reset pattern
			didBoot = true;
		};

		if (didBoot) {
			// Only wipe the tree on fresh boot, before MPB is constructed
			Server.default.bind({
				s.initTree;
				s.defaultGroup.freeAll;
			});
		};

		^didBoot
	}


	tryPlayNdefs { arg syms;
		syms.do { arg sym;
			var nd = Ndef(sym);
			if (nd.notNil) { nd.play; };
		};
	}

	showStatus {
		logger.info("SystemStatus", "Pedalboard: %, CommandManager: %".format(
			pedalboard, commandManager
		));
	}

/*    shutdownAll {
        pedalboard.free;
        pedalboardGUI.close;
        if (statusDisplay.notNil) { statusDisplay.close };
        logger.warn("Shutdown", "LivePedalboardSystem shut down.");
    }*/
	shutdownAll {
		var runnerClosed;

		runnerClosed = false;

		if (pedalboard.notNil and: { pedalboard.respondsTo(\free) }) {
			pedalboard.free;
		};

		if (pedalboardGUI.notNil) {
			if (pedalboardGUI.respondsTo(\close)) {
				pedalboardGUI.close; runnerClosed = true;
			};
			if (runnerClosed.not and: { pedalboardGUI.respondsTo(\stop) }) {
				pedalboardGUI.stop; runnerClosed = true;
			};
			if (runnerClosed.not and: { pedalboardGUI.respondsTo(\free) }) {
				pedalboardGUI.free; runnerClosed = true;
			};
		};

		if (statusDisplay.notNil and: { statusDisplay.respondsTo(\close) }) {
			statusDisplay.close;
		};

		logger.warn("Shutdown", "LivePedalboardSystem shut down.");
	}
}
