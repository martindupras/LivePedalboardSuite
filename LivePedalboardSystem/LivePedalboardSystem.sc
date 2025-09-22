// LivePedalboardSystem.sc
// v0.2.5
// MD 2025-09-21 22:05

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
        defaultPath = Platform.userExtensionDir ++ "/MDclasses/LivePedalboardSystem/MagicPedalboardCommandTree.json";
        treeFilePath = treePath.ifNil { defaultPath };
        ^this;
    }

    bringUpAll {
        this.bringUpPedalboard;
        this.bringUpCommandSystem;
        this.bringUpMagicDisplayGUI;
        this.ensureAudioOn;
        logger.info("LivePedalboardSystem", "✅ System is ready.");
        ^this;
    }

    bringUpPedalboard {
        pedalboard = MagicPedalboard.new;
        pedalboardGUI = MagicPedalboardTestRunner.new(pedalboard, nil);
        pedalboardGUI.bringUp;
        logger.info("Pedalboard", "Pedalboard and GUI initialized.");
    }

    bringUpCommandSystem {
        commandManager = CommandManager.new(treeFilePath);

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
    bringUpMagicDisplayGUI {
        // Create your existing MagicDisplayGUI (no "openUnique" in your class)
        statusDisplay = MagicDisplayGUI.new;  // constructor signature matches your file
        // Set initial text using your API: showExpectation(...)
        statusDisplay.showExpectation("System ready.", 0);  // MagicDisplayGUI has no updateStatus
        // Share GUI with CommandManager so CommandManager:setStatus can target it
        if (commandManager.respondsTo(\display_)) { commandManager.display = statusDisplay; };

        // Ensure meter SynthDefs are present before enabling
        this.ensureMeterDefs;
        statusDisplay.enableMeters(true);
    }

    // --- Provide \busMeterA / \busMeterB if they don't exist yet ---
/*    ensureMeterDefs {
        Server.default.bind({
            var hasA, hasB;
            hasA = SynthDescLib.global.at(\busMeterA).notNil;
            hasB = SynthDescLib.global.at(\busMeterB).notNil;

            if (hasA.not) {
                SynthDef(\busMeterA, { arg inBus, rate = 24;
                    var sig = In.ar(inBus, 2);
                    var amp = Amplitude.ar(sig).clip(0, 1);
                    SendReply.kr(Impulse.kr(rate), '/ampA', A2K.kr(amp));
                }).add;
            };

            if (hasB.not) {
                SynthDef(\busMeterB, { arg inBus, rate = 24;
                    var sig = In.ar(inBus, 2);
                    var amp = Amplitude.ar(sig).clip(0, 1);
                    SendReply.kr(Impulse.kr(rate), '/ampB', A2K.kr(amp));
                }).add;
            };
        });
    }*/

	// replaced with the below, which uses MAgicDisplay meters instead:

    ensureMeterDefs {
        MagicDisplay.ensureMeterDefs(2); // or MagicDisplay.setMeterChannels(2)
    }


    // --- Conservative "make sure something is audible" ---
    ensureAudioOn {
        var started;
        started = false;

        if (pedalboard.respondsTo(\start)) { pedalboard.start; started = true; }
        { if (pedalboard.respondsTo(\play)) { pedalboard.play; started = true; } };

        if (started.not) {
            this.tryPlayNdefs([\chainA, \chainB, \testmelody]);
        };

        // Optional: if you expect stereo, declare channel count before play once
        // Ndef(\chainA).numChannels_(2);
        // Ndef(\chainB).numChannels_(2);

        logger.info("Audio", "ensureAudioOn called (started: %).".format(started));
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

    shutdownAll {
        pedalboard.free;
        pedalboardGUI.close;
        if (statusDisplay.notNil) { statusDisplay.close };
        logger.warn("Shutdown", "LivePedalboardSystem shut down.");
    }
}
