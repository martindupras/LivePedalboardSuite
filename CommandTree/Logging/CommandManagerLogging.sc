// CommandManagerLogging
// v1.0.1
// MD 20220923-1222

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


	// added 20250923

	  // Build a slash path (without "root") from the builder's current node, e.g.
  //  "root -> chain -> add -> audio -> timebased -> delay"
  //   -> "/chain/add/audio/timebased/delay"
  buildLongPathFromBuilder { arg builderRef;
    var names, raw, filtered;
    if(builderRef.isNil or: { builderRef.currentNode.isNil }) { ^"/" };
    names = builderRef.currentNode.getPathToRoot; // List from root..current
    // drop "root", to-lower is not required (your names are already lower)
    filtered = names.copyRange(1, names.size - 1);
    raw = "/" ++ filtered.join("/");
    ^raw;
  }

  // Map long tree paths to short canonical "/verb/..." understood by MPB.
  canonicalizeCommandPath { arg rawPath;
    var parts, first;
    parts = rawPath.asString.split($/).reject({ arg s; s.size == 0 });
    if(parts.size == 0) { ^rawPath.asString };
    first = parts[0].asString;

    // switch family → "/switch"
    if(first == "switch") { ^"/switch" };

    // chain/*
    if(first == "chain") {
      if(parts.size >= 3) {
        var second = parts[1].asString;
        // /chain/add/audio/.../<effect> -> /add/<effect>
        if(second == "add" and: { parts[2].asString == "audio" }) {
          ^("/add/" ++ parts.last.asString);
        };
        // /chain/setsource/audio/source/<src> -> /setSource/<src>
        if(second == "setsource"
          and: { parts.size >= 5 }
          and: { parts[2].asString == "audio" }
          and: { parts[3].asString == "source" }) {
          ^("/setSource/" ++ parts.last.asString);
        };
      };
      ^rawPath.asString; // fall through
    };

    // already-canonical short forms
    if(#["add","remove","clear","bypass","swap","setSource","switch"].includes(first)) {
      ^("/" ++ parts.join("/"));
    };

    ^rawPath.asString;
  }

  // One-shot helper from builder → CANONICAL short path.
  canonicalPathFromBuilder { arg builderRef;
    var longPath, shortPath;
    longPath = this.buildLongPathFromBuilder(builderRef);
    shortPath = this.canonicalizeCommandPath(longPath);
    ^shortPath;
  }



}
