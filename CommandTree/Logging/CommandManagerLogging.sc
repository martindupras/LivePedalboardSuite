// CommandManagerLogging
// v1.0.0
// MD 2025-09-22 09:52 BST

/*
Purpose
- See file comments for details.
Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/


+ CommandManager {

    logInit { |treePathString|
        this.mdlog(2, "CommandManager", "✅ created; treePath=" ++ treePathString);
        ^this
    }

    setStatus { |text|
        if(display.notNil and: { display.respondsTo(\showExpectation) }) {
            display.showExpectation(text, 0);
        }{
            this.mdlog(2, "CommandManager", "Status: " ++ text);
        };
        ^this
    }

    createNewTree {
        tree = MDCommandTree.new("root");
        tree.importJSONFile(filePath);
        if(tree.notNil) {
            this.mdlog(2, "CommandManager", "📥 tree imported: " ++ filePath);
            this.mdlog(3, "CommandManager", "tree pretty-print follows…");
            tree.printTreePretty;
        }{
            this.mdlog(1, "CommandManager", "⚠ couldn't create/import tree");
        };
        ^this
    }

    createBuilder {
        builder = MDCommandBuilder.new(tree);
        if(builder.notNil) {
            this.mdlog(2, "CommandManager", "🔭 builder created");
        }{
            this.mdlog(1, "CommandManager", "⚠ couldn't create builder");
        };
        ^this
    }

    createCommandQueue {
        queue = MDCommandQueue.new;
        if(queue.notNil) {
            this.mdlog(2, "CommandManager", "📦 queue created");
        }{
            this.mdlog(1, "CommandManager", "⚠ couldn't create queue");
        };
        ^this
    }

    reloadTreeFromPath { |path|
        if(path.notNil) { filePath = path; };
        this.createNewTree;
        builder = MDCommandBuilder.new(tree);
        this.setStatus("✅ tree reloaded from: " ++ filePath);
        this.mdlog(2, "CommandManager", "✅ tree reloaded: " ++ filePath);
        ^this
    }
}
