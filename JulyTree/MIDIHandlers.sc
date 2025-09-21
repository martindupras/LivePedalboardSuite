//MIDIHandlers.sc
// MD 20250818
// taken out of MIDIInputManager.sc to make smaller file and cleaner organisation.

MIDIInputHandler {
	var <>inputManager;

	*new { |inputManager| ^super.new.init(inputManager); }

	init { |inputManager|
		this.inputManager = inputManager;
		^this
	}

	handleMessage { |channel, type, value|
		"MIDIInputHandler: % % %".format(channel, type, value).postln;
	}
}

LaunchpadHandler  {
	var <>inputManager;

	*new { |inputManager| ^super.new.init(inputManager); }

	init { |inputManager|
		this.inputManager = inputManager;
		^this
	}

	handleMessage { |channel, type, value|
		"Launchpad: % % %".format(channel, type, value).postln;
	}
}

LaunchpadDAWHandler {
	var <>inputManager;

	*new { |inputManager| ^super.new.init(inputManager); }

	init { |inputManager|
		this.inputManager = inputManager;
		^this
	}

	handleMessage { |channel, type, value|
		// Intentionally left blank to ignore DAW messages
	}
}

FootControllerHandler {
	var <>inputManager;

	*new { |inputManager|
		if (inputManager.isNil) {
			Error("FootControllerHandler requires a inputManager").throw;
		};
		^super.new.init(inputManager);
	}

	init { |inputManager|
		this.inputManager = inputManager;
		("✅ FootControllerHandler received inputManager: " ++ inputManager).postln;
		^this
	}

	handleMessage { |channel, type, value|
		("🧪 inputManager class is: " ++ inputManager.class).postln;


		if (type === \noteOn) {
			switch (value,
				36, { inputManager.setMode(inputManager.modes[\idle]) },
				38, { inputManager.setMode(inputManager.modes[\prog]) },
				40, { inputManager.setMode(inputManager.modes[\queue]) },
				41, { inputManager.setMode(inputManager.modes[\send]) },
				{ ("⚠️ No action for note: " ++ value).postln }
			);
		}
	}
}

GuitarMIDIHandler {
	var <>inputManager;

	*new { |inputManager|
		var instance = super.new;
		instance.init(inputManager);
		^instance
	}

	init { |inputManager|
		this.inputManager = inputManager;
		("✅ GuitarMIDIHandler received inputManager: " ++ inputManager).postln;
		^this
	}

	handleMessage { |channel, type, pitch|
		var stringBasePitches, basePitch, fret, stringNumber;

		// ✅ Confirm method is being called
		("📥 handleMessage called with channel: " ++ channel ++ ", type: " ++ type ++ ", pitch: " ++ pitch).postln;

		// ✅ Check type
		if (type === \noteOn) {
			"✅ type is noteOn".postln;
		} {
			"❌ type is not noteOn".postln;
		};

		// ✅ Check current mode
		if (inputManager.currentMode == inputManager.modes[\prog]) {
			"✅ currentMode is prog".postln;

			stringBasePitches = (
				0: 40, // E string (6th)
				1: 45, // A
				2: 50, // D
				3: 55, // G
				4: 59, // B
				5: 64  // E (1st)
			);

			basePitch = stringBasePitches[channel];
			if (basePitch.notNil) {
				fret = pitch - basePitch;
				stringNumber = 6 - channel;

				("🎸 Received MIDI note: " ++ pitch ++
					" on channel: " ++ channel ++
					" → string: " ++ stringNumber ++
					", base pitch: " ++ basePitch ++
					", calculated fret: " ++ fret).postln;

				// ✅ Navigation logic
				if (inputManager.waitingForString == stringNumber) {
					inputManager.waitingForString = nil;
					inputManager.navigationCallback.value(fret);
				};
			} {
				("⚠️ Unrecognized channel: " ++ channel ++ ". No base pitch defined.").postln;
			}
		} {
			("❌ currentMode is: " ++ inputManager.currentMode).postln;
		};

		{ inputManager.parentCommandManager.updateDisplay; }.defer;
	}
}