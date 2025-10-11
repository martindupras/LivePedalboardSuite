// CommandManager.sc
// v2
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
	var <>lpDisplay;

	var launchpadHandlerRef, footHandlerRef, guitarHandlerRef, dawHandlerRef;

	var <>launchpadID, <>footControllerID, <>guitarID;

	*new { arg anLpDisplay;
		^super.new.init(anLpDisplay);
	}


	init { arg anLpDisplay;

		lpDisplay = anLpDisplay;
		// statusDisplay = LPDisplayAdapter.new(anLpDisplay);
		//who actually needs this?

		currentState = \idle;
		//this.initCircularFileSaveStuff ;

		this.createNewTree;        // will harden path again inside
		this.createBuilder;
		this.createCommandQueue;

		// midiManager = MIDIInputManager.new(builder, nil, nil, nil);
		midiManager = MIDIInputManager.new(builder, nil, nil, nil, nil);

		midiManager.parentCommandManager = this;
		this.displayTest();

		^this
	}

	displayTest{
		lpDisplay.sendPaneText(\choices, 'Hello from command manager');

	}



	initCircularFileSaveStuff {
		var defaultPath, savedPath, stateDir, stateFile;
		var explicitOk, savedOk;
		var treePath;
		treePath = nil;
		// saver = CircularFileSave.new("myTree", "~/CommandTreeSavefiles", 10);
		saver = CircularFileSave.new("myTree", nil, 10);
// or simply: saver = CircularFileSave.new("myTree");


		stateDir  = Platform.userExtensionDir ++ "/LivePedalboardSuite/.state";
		stateFile = stateDir ++ "/LastCommandTreePath.txt";

		defaultPath = Platform.userExtensionDir
		++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";

		savedPath = this.readLastPath(stateFile); // <- empty/whitespace -> nil

		explicitOk = treePath.isString and: { treePath.size > 0 };
		savedOk    = savedPath.isString and: { savedPath.size > 0 } and: { File.exists(savedPath) };

		filePath = if (explicitOk) { treePath } { if (savedOk) { savedPath } { defaultPath } };

		if (filePath.isString and: { filePath.size > 0 }) {
			this.writeLastPath(stateDir, stateFile, filePath);
		};
	}


	// --- Build pieces --------------------------------------------------------

	createNewTree {
		var usePath;
		// final guard before import: ensure a usable String path
		usePath = filePath;
		if (usePath.isString.not or: { usePath.size <= 0 }) {
			usePath = Platform.userExtensionDir
			++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";
		};
		if (File.exists(usePath).not) {
			// last resort: keep going with default even if missing (import will warn gracefully)
			usePath = Platform.userExtensionDir
			++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";
		};

		tree = MDCommandTree.new("root");
		tree.importJSONFile(usePath);

		if (tree.notNil) {
			"📥 Tree imported from ".post; usePath.postln;
		}{
			"📥 Couldn't create/import tree.".postln;
		};
		^this
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

	// --- tiny helpers (inside the same class) ---

	writeLastPath { arg dirPath, filePath, pathToWrite;
		var okDir;
		// guard: do nothing if not a non-empty String
		if (pathToWrite.isString.not or: { pathToWrite.size <= 0 }) { ^this };

		okDir = PathName(dirPath).isFolder;
		if (okDir.not) { File.mkdir(dirPath) };

		File.use(filePath, "w", { |fh| fh.write(pathToWrite) });
		^this
	}

	readLastPath { arg filePath;
		var content, cleaned, hasNonSpace;
		if (File.exists(filePath)) {
			File.use(filePath, "r", { |fh| content = fh.readAllString });
			// collapse whitespace-only to nil
			cleaned = content ? "";
			hasNonSpace = false;
			cleaned.do { |ch|
				if ((ch != $\ ) and: { ch != $\t } and: { ch != $\n } and: { ch != $\r }) {
					hasNonSpace = true;
				}
			};
			if (hasNonSpace.not) { content = nil };
		};
		^content
	}


/*	updateDisplay {
		var guiRef, modeText, choiceLines;

		guiRef = display;   // may be nil
		if (guiRef.isNil) { ^this };

		modeText = "Mode: " ++ (currentState ? \idle).asString;

		// build "fret X → Name" lines from the builder's current node
		choiceLines = if (builder.notNil and: { builder.currentNode.notNil }) {
			builder.currentNode.children.collect({ |ch|
				("fret " ++ ch.fret.asString ++ " → " ++ ch.name.asString)
			})
		} { [] };

		{
			if (guiRef.respondsTo(\showExpectation)) {
				guiRef.showExpectation(modeText, 0);
			};
			if (guiRef.respondsTo(\updateTextField)) {
				guiRef.updateTextField(\state, modeText);
				guiRef.updateTextField(\choices, choiceLines.join("\n"));
			};
			// NEW: update choices panel in MagicDisplayGUI if present
			if (guiRef.respondsTo(\setOperations)) {
				guiRef.setOperations(choiceLines);
			};
		}.defer;

		^this
	}*/

// updated 20250924-1209
	updateDisplay {
    var guiRef, modeText, choiceLines;
    guiRef = display; // may be nil
    if (guiRef.isNil) { ^this };
    modeText = "Mode: " ++ (currentState ? \idle).asString;

    // build "fret X → Name" lines from the builder's current node
    choiceLines = if (builder.notNil and: { builder.currentNode.notNil }) {
        builder.currentNode.children.collect({ arg ch;
            ("fret " ++ ch.fret.asString ++ " → " ++ ch.name.asString)
        })
    } { [] };

    {
        if (guiRef.respondsTo(\showExpectation)) {
            guiRef.showExpectation(modeText, 0);
        };
        if (guiRef.respondsTo(\updateTextField)) {
            guiRef.updateTextField(\state, modeText);
            guiRef.updateTextField(\choices, choiceLines.join("\n"));
        };
        if (guiRef.respondsTo(\setOperations)) {
            guiRef.setOperations(choiceLines);
        };
    }.defer;
    ^this
}

}

// Back-compat alias
MDCommandMC : CommandManager {}
