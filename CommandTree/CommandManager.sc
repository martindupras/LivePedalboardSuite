// CommandManager.sc
// v1.5
// MD 20250921-22:40

// Purpose: Central controller; uses injected display (MagicDisplayGUI), does NOT create windows.
// Style: var-first, AppClock.defer for UI, no server.sync. Tree path is configurable in *new/init.

CommandManager {
    var <>currentState;
    var <>tree;
    var <>builder;
    var <>queue;
    var <>display, <>displayText;
    var <>filePath;
    var <>midiManager;
    var <>parentCommandManager;
    var <>saver;
    var <>queueExportCallback;

    var launchpadHandler, footControllerHandler, guitarHandler;
    var <>launchpadID, <>footControllerID, <>guitarID;

    *new { arg treePath;
        ^super.new.init(treePath);
    }

    init { arg treePath;
        var defaultPath;
        if (true) { "CommandManager created".postln };
        currentState = \idle;

        saver = CircularFileSave.new("myTree", "~/CommandTreeSavefiles", 10);

        defaultPath = Platform.userExtensionDir ++ "/MDclasses/LivePedalboardSystem/MagicPedalboardCommandTree.json";
        filePath = treePath.ifNil { defaultPath };

        this.createNewTree;
        this.createBuilder;
        this.createCommandQueue;

        // IMPORTANT: Do NOT create a UserDisplay here; we inject MagicDisplayGUI from LPS.
        // display = UserDisplay.new;

        midiManager = MIDIInputManager.new(builder, nil, nil, nil);
        midiManager.parentCommandManager = this;

        ^this
    }

    // --- Build pieces --------------------------------------------------------

    createNewTree {
        tree = MDCommandTree.new("root");
        tree.importJSONFile(filePath);  // uses your chosen/default path
        if (tree.notNil) {
            "📥 Tree imported from ".post; filePath.postln;
            if (true) { tree.printTreePretty };  // optional debug
        }{
            "📥 Couldn't create/import tree.".postln;
        }
    }

    createBuilder {
        builder = MDCommandBuilder.new(tree);
        if (builder.notNil) {
            if (true) { "🔮 Builder created".postln };
        }{
            "🔮 Couldn't create builder".postln;
        }
    }

    createCommandQueue {
        queue = MDCommandQueue.new;
        if (queue.notNil) {
            if (true) { "📦 Queue created".postln };
        }{
            "📦 Couldn't create queue".postln;
        }
    }

    // --- Display passthrough -------------------------------------------------

    setStatus { arg text;
        // If a MagicDisplayGUI is injected, use showExpectation (no updateStatus in that class)
        if (display.notNil and: { display.respondsTo(\showExpectation) }) {
            display.showExpectation(text, 0);
        }{
            ("Status: " ++ text).postln;
        }
    }

    // Optional hot-reload from a new path
    reloadTreeFromPath { arg path;
        if (path.notNil) { filePath = path; };
        this.createNewTree;
        builder = MDCommandBuilder.new(tree);
        this.setStatus("✅ Tree reloaded from: " ++ filePath);
    }
}

// Back-compat alias
MDCommandMC : CommandManager {}
