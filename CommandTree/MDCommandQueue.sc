// MDCommandQueue.sc
// Refactored for clarity and consistency
// MD 20250818



MDCommandQueue {
    var <>commandList;

    *new { ^super.new.init(); }

    init {
        commandList = List.new(8);
        Verbosity.postIf(1, "✅ CommandQueue initialized");
        ^this
    }

    enqueueCommand { |command|
        commandList.add(command);
        Verbosity.postIf(1, "📥 Command added: " ++ command);
        Verbosity.postIf(2, "📦 Current queue: " ++ commandList);
        ^commandList
    }

    dequeueLastCommand {
        if (commandList.notEmpty) {
            commandList.removeAt(commandList.size - 1);
            Verbosity.postIf(1, "🗑 Last command removed");
        } {
            Verbosity.postIf(0, "⚠ No command to remove");
        };
        ^commandList
    }

    clearQueue {
        commandList.clear;
        Verbosity.postIf(1, "🧹 Queue cleared");
        ^this
    }

    exportAsOSCPath {
        var oscPath;

        oscPath = "/" ++ commandList.collect { |cmd|
            cmd.asString;
        }.join("/");

        ~commandToSend = oscPath;
        Verbosity.postIf(2, "🚀 Exported OSC path: " ++ oscPath);
        ^oscPath
    }
}

// MDCommandQueue {
// 	var <>commandList;
//
// 	*new { ^super.new.init(); }
//
// 	init {
// 		commandList = List.new(8);
// 		"CommandQueue initialized".postln;
// 		^this
// 	}
//
// 	enqueueCommand { |command|
// 		commandList.add(command);
// 		("Command added: " ++ command).postln;
// 		("Current queue: " ++ commandList).postln;
// 		^commandList
// 	}
//
// 	dequeueLastCommand {
// 		if (commandList.notEmpty) {
// 			commandList.removeAt(commandList.size - 1);
// 			"Last command removed".postln;
// 		} {
// 			"⚠No command to remove".postln;
// 		};
// 		^commandList
// 	}
//
// 	clearQueue {
// 		commandList.clear;
// 		"🧹 Queue cleared".postln;
// 		^this
// 	}
//
//
// 	exportAsOSCPath {
// 		var oscPath;
//
// 		oscPath = "/" ++ commandList.collect { |cmd|
// 			cmd.asString;
// 		}.join("/");
//
// 		~commandToSend = oscPath;
// 		("Exported OSC path: " ++ oscPath).postln;
// 		^oscPath
// 	}
// }