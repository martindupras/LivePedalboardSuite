// CommandManager.sc
// Refactored from MDCommandMC.sc
// MD 20250813

//previously known as MDCommandMC
OldCommandManager {
    var something, octave, pitchclass, gString;
    var currentState;
    var states;
    var tree;
    var builder;
    var queue;
    var display, displayText;
    var filePath;
    var midiManager;

    var launchpadHandler, footControllerHandler, guitarHandler;
    var launchpadID, footControllerID, guitarID;

    *new {
        ^super.new.init;
    }

    init {
        if (true) { "CommandManager created".postln };

        states = [\idle, \inTree, \inQueue];
        currentState = \idle;

        filePath = "~/Command Tree savefiles/myTree.json".standardizePath;

        this.createNewTree;
        this.createBuilder;
        this.createCommandQueue;
        display = UserDisplay.new;

        launchpadHandler = LaunchpadHandler.new;
        footControllerHandler = FootControllerHandler.new;
        guitarHandler = GuitarMIDIHandler.new;

        midiManager = MIDIInputManager.new(builder, launchpadHandler, footControllerHandler, guitarHandler);

        ^this
    }

/* RETIRED */
	// initMIDI {
	// 	launchpadID = midiManager.getSrcID(\LPMiniMK3_MIDI_Out);
	// 	footControllerID = midiManager.getSrcID(\KEYBOARD);
	// 	guitarID = midiManager.getSrcID(\to_SC);
	// }

    createNewTree {
        tree = MDCommandTree.new("root");
        tree.importJSONFile(filePath);
        if (tree.notNil) {
            "🔮 Tree created".postln;
            if (true) { tree.printTreePretty };
        } {
            "🔮 Couldn't create tree".postln;
        }
    }

    createBuilder {
        builder = MDCommandBuilder.new(tree);
        if (builder.notNil) {
            "🔮 Builder created".postln;
        } {
            "🔮 Couldn't create builder".postln;
        }
    }

    createCommandQueue {
        queue = MDCommandQueue.new;
        if (queue.notNil) {
            "🔮 Queue created".postln;
        } {
            "🔮 Couldn't create queue".postln;
        }
    }

    print { |vel, num, chan|
        ("vel: " + vel).postln;
        ("num: " + num).postln;
        ("chan: " + chan).postln;
        ^this
    }
}

// alias to old name
OldMDCommandMC : CommandManager {}