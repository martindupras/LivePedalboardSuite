// MIDIInputManager.sc
// v1.1.1
// v1.1 added things in send mode for LivePedalboardSystem
// MD 20250817-1926

MIDIInputManager {
	var <>deviceUIDs;         // Dict: symbolic name -> srcID
	var <>deviceHandlers;     // Dict: srcID -> handler object

	var <> currentMode = \idle; // will store the mode that the foot controller has put us in
	var <> builder, <>queue;
	var <> parentCommandManager;
	var <> modes;
	var <>waitingForString, <>navigationCallback;
	var <>lastEnqueuedPayload;


	// Legacy vars for debugging
	var <>launchpadHandler, <>footControllerHandler, <>guitarHandler, <>launchpadDAWHandler;
	var <>launchpadID, <>footControllerID, <>guitarID, <>launchpadDAWID;

	*new { |builder, launchpad, footController, guitarMIDI, launchpadDAW|
		^super.new.init(builder, launchpad, footController, guitarMIDI, launchpadDAW);
	}

	init { |argBuilder, argLaunchpad, argFootController, argGuitarMIDI, argLaunchpadDAW|

		this.modes = IdentityDictionary[
			\idle -> \idle,
			\prog -> \prog,
			\queue -> \queue,
			\send -> \send,
			\play -> \play,
			\numeric -> \numeric,
			\capture -> \capture,
			\record -> \record
		];

		this.builder = argBuilder;
		this.queue = MDCommandQueue.new;

		this.launchpadHandler = argLaunchpad ?? LaunchpadHandler.new;
		this.footControllerHandler = argFootController ?? FootControllerHandler.new(this);
		//DEBUG:
		("footControllerHandler manager is: " ++ footControllerHandler.inputManager).postln;

		this.guitarHandler = argGuitarMIDI ?? GuitarMIDIHandler.new(this);
		this.launchpadDAWHandler = argLaunchpadDAW ?? LaunchpadDAWHandler.new;

		MIDIClient.init;
		MIDIIn.connectAll;

		deviceUIDs = Dictionary.new; // store (device, UID) pairs
		deviceHandlers = Dictionary.new; // store (device, handler) pairs

		this.scanDevices;

		launchpadID = this.getDeviceSrcID(\Launchpad_Mini_MK3_LPMiniMK3_MIDI_Out);
		launchpadDAWID  = this.getDeviceSrcID(\Launchpad_Mini_MK3_LPMiniMK3_DAW_Out); // so that we can filter it out
		footControllerID = this.getDeviceSrcID(\nanoKEY2_KEYBOARD);
		guitarID = this.getDeviceSrcID(\MD_IAC_to_SC);

		//DEBUG:
		("LaunchpadDAWHandler is: " ++ launchpadDAWHandler).postln;

		this.bindDevice(launchpadID, launchpadHandler);
		this.bindDevice(footControllerID, footControllerHandler);
		this.bindDevice(guitarID, guitarHandler);
		this.bindDevice(launchpadDAWID, launchpadDAWHandler);

		this.setupMIDIDef;
		^this
	}

	setMode { |newMode|
		currentMode = newMode;
		parentCommandManager.currentState = newMode;
		this.handleModeChange(newMode);
		{ parentCommandManager.updateDisplay }.defer;
	}

	handleModeChange { |mode|
		switch(mode,
			modes[\idle], {
				queue.clear;
				builder.resetNavigation;
				"Tree navigation reset.".postln;
			},

			modes[\prog], {
				var root;

				builder.resetNavigation;

				root = builder.tree.root; // get the root
				if (root.notNil) {
					root.children.do { |child| ("• " ++ child.name).postln };
				};

				this.startNavigationFromString(6);

				"Tree navigation started.".postln;
			},

			//---


      modes[\queue], {
        var queueText, canonicalPath;

        // NEW: derive canonical short path from current CommandTree selection
        canonicalPath = parentCommandManager.canonicalPathFromBuilder(builder);

        if (canonicalPath != lastEnqueuedPayload) { // reuse dedupe guard
          ("Current canonical to queue: " ++ canonicalPath).postln;
          queue.enqueueCommand(canonicalPath);
          lastEnqueuedPayload = canonicalPath;

          if (builder.isAtLeaf) {
            parentCommandManager.setStatus("🌿 Leaf → " ++ canonicalPath);
          } {
            parentCommandManager.setStatus("📥 Queued node: " ++ canonicalPath);
          };

          queueText = queue.commandList.collect({ arg cmd; "- " ++ cmd.asString }).join("\n");
          {
            parentCommandManager.display.updateTextField(\state, "Mode: queue");
            parentCommandManager.display.updateTextField(\queue, "Current Queue:\n" ++ queueText);
            parentCommandManager.display.updateTextField(\lastCommand, "Last Added: " ++ canonicalPath);
          }.defer;

        } {
          ("⚠️ Duplicate canonical ignored: " ++ canonicalPath).postln;
          parentCommandManager.setStatus("⚠️ Duplicate canonical ignored");
        };

        builder.resetNavigation;
        "Added canonical to queue and restarted navigation.".postln;
        this.setMode(modes[\prog]); // unchanged
      },

			//---

/*			modes[\send], {
				var path = queue.exportAsOSCPath;
				("Queue contents before export: " ++ queue.commandList).postln;

				("Sent queue as OSC: " ++ path).postln;
				queue.clear;
			},*/

			modes[\send], {
				var path = queue.exportAsOSCPath;
				("Queue contents before export: " ++ queue.commandList).postln;
				("Sent queue as OSC: " ++ path).postln;
				if (parentCommandManager.notNil and: { parentCommandManager.queueExportCallback.notNil }) {
					parentCommandManager.queueExportCallback.value(path);
				};
				queue.clear;
			},

			modes[\play], {
				"🎸 Play mode: no interaction.".postln;
			},
			modes[\numeric], {
				"🔢 Numeric input mode (not yet implemented).".postln;
			},
			modes[\capture], {
				"🎼 Capture mode (not yet implemented).".postln;
			},
			modes[\record], {
				"🔴 Record mode (not yet implemented).".postln;
			}
		);
	}
	startNavigationFromString { |stringNum|
		if (stringNum < 1) {
			builder.navigationComplete = true;
			"✅ Navigation complete.".postln;
			^this;
		};

		this.listenForNoteFromString(stringNum, { |fret|
			builder.navigateByFret(stringNum, fret);
			this.startNavigationFromString(stringNum - 1);
		});
	}

	listenForNoteFromString { |stringNum, callback|
		waitingForString = stringNum;
		navigationCallback = callback;
		("🎧 Waiting for note on string " ++ stringNum).postln;
	}

	scanDevices {
		MIDIClient.sources.do { |src|
			var symbol = (src.device ++ "_" ++ src.name)
			.replace(" ", "_")
			.replace("-", "_")
			.asSymbol;
			deviceUIDs[symbol] = src.uid;
		};
	}

	listDevices {
		"🎛 Connected MIDI Devices:".postln;
		deviceUIDs.keysValuesDo { |symbol, uid|
			("% => %".format(symbol, uid)).postln;
		};
	}

	getDeviceSrcID { |symbol|
		^deviceUIDs[symbol];
	}

	listDeviceSymbols {
		deviceUIDs.keysValuesDo { |symbol, uid|
			("Symbol: " ++ symbol ++ " → UID: " ++ uid).postln;
		};
	}

	bindDevice { |keyOrID, handler|
		var srcID, symbol;

		if (keyOrID.isKindOf(Symbol)) {
			srcID = this.getDeviceSrcID(keyOrID);
			symbol = keyOrID;
		}{
			srcID = keyOrID;
			symbol = deviceUIDs.keys.detect { |k| deviceUIDs[k] == srcID };
		};

		if (srcID.isNil) {
			("⚠️ Could not bind device: " ++ keyOrID ++ " (srcID is nil)").warn;
			^this;
		};

		if (handler.isNil) {
			("⚠️ No handler provided for srcID: " ++ srcID).warn;
			^this;
		};

		deviceHandlers[srcID] = handler;
		("🔗 Bound %" ++ " (% srcID) to handler %")
		.format(symbol, srcID, handler.class.name)
		.postln;
	}

	setupMIDIDef {
		MIDIdef.noteOn(\midiToManager, { |vel, num, chan, srcID|
			var handler = deviceHandlers[srcID];
			if (handler.notNil) {
				handler.handleMessage(chan, \noteOn, num);
			} {
				("⚠️ No handler bound for srcID: " + srcID).postln;
			}
		});
	}

} // end of MIDIInputManager class

