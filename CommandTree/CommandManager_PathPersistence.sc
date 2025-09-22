// CommandManager_PathPersistence.sc
// v1.0 — 2025-09-22 MD
// Purpose: Remember last used tree path across runs.
// Style: var-first; lowercase; no server.sync.

+ CommandManager {
    var <lastPathFile;

    init { |treePath|
        var defaultPath;
        lastPathFile = Platform.userExtensionDir ++ "/MDclasses/LivePedalboardSystem/last_tree_path.txt";
        defaultPath = Platform.userExtensionDir ++ "/MDclasses/LivePedalboardSystem/MagicPedalboardCommandTree.json";

        // Load last path if treePath is nil
        if(treePath.isNil) {
            treePath = this.readLastPath ?? defaultPath;
        };

        filePath = treePath;
        this.writeLastPath(filePath); // persist for next time

        // existing init logic continues...
        this.createNewTree;
        this.createBuilder;
        this.createCommandQueue;
        midiManager = MIDIInputManager.new(builder, nil, nil, nil);
        midiManager.parentCommandManager = this;
        ^this
    }

    writeLastPath { |path|
        File.use(lastPathFile, "w", { |f| f.write(path) });
    }

    readLastPath {
        var content;
        if(File.exists(lastPathFile)) {
            File.use(lastPathFile, "r", { |f| content = f.readAllString });
        };
        ^content
    }
}
