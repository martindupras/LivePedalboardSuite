// MDCommandBuilder.sc
// v0.2
// MD 20250924-1008

/*
Purpose
- Fold mdlog instrumentation into the base class (Option A).
- Keep existing console messages; add small legacy shims so old tests keep working.
Style
- var-first; descriptive variable names; no single-letter locals; lowercase; no server.sync.
- Minimal changes; preserve your current behavior.
*/

MDCommandBuilder {
    var <>tree, <>currentNode, <>currentCommand, <>fretPath;
    var <>navigationComplete = false;

    *new { arg argTree;  ^super.new.init(argTree); }

    init { arg argTree;
        tree = argTree;
        currentNode = tree.root;
        fretPath = List[0];
        "CommandBuilder initialized".postln;
        ^this
    }

/*    printChildren {
        var childrenNames;

        if (currentNode.children.notEmpty) {
            currentNode.children.do({ arg childItem;
                ("🎚️ Fret: " ++ childItem.fret ++ " → " ++ childItem.name).postln;
            });
            childrenNames = currentNode.children.collect({ arg childItem; childItem.name });
            this.mdlog(3, "CommandBuilder", "children=" ++ childrenNames);
        } {
            "⚠️ No children".postln;
            this.mdlog(1, "CommandBuilder", "no children at node=" ++ currentNode.name);
        };
        ^childrenNames
    }*/

/*    navigateByFret { arg stringLevel, fretNumber;
        var nextNode;

        this.mdlog(2, "CommandBuilder",
            "🎸 navigateByFret fret=" ++ fretNumber ++ " stringLevel=" ++ stringLevel);

        ("🎸 Navigating by fret: " ++ fretNumber).postln;
        nextNode = currentNode.getChildByFret(fretNumber);

        if (nextNode.notNil) {
            currentNode = nextNode;
            fretPath.add(currentNode.fret);
            ("Current node: " ++ currentNode.name).postln;
            this.mdlog(2, "CommandBuilder", "current=" ++ currentNode.name);
        } {
            ("⚠️ No child found for fret: " ++ fretNumber).postln;
            this.mdlog(1, "CommandBuilder", "no child for fret=" ++ fretNumber);
        };
        ^currentNode
    }*/

/*    navigateByName { arg stringLevel, childName;
        var nextNode;

        nextNode = currentNode.getChildByName(childName);

        if (nextNode.notNil) {
            currentNode = nextNode;
            fretPath.add(currentNode.fret);
            ("Current node: " ++ currentNode.name).postln;
            ("Path: " ++ currentNode.getFullPathString).postln;
            this.mdlog(2, "CommandBuilder", "current=" ++ currentNode.name);
            this.mdlog(3, "CommandBuilder", "path=" ++ currentNode.getFullPathString);
        } {
            var availableNames;
            availableNames = currentNode.children.collect({ arg childItem; childItem.name }).join(", ");
            ("⚠️ Available children: " ++ availableNames).postln;
            this.mdlog(1, "CommandBuilder", "not found; available=" ++ availableNames);
        };
        ^currentNode
    }*/

/*    printPathToRoot {
        currentNode.getPathToRoot.postln;
        this.mdlog(3, "CommandBuilder", "📍 path=" ++ currentNode.getPathToRoot);
        ^this
    }*/

/*    getCurrentName {
        currentNode.name.postln;
        this.mdlog(3, "CommandBuilder", "currentName=" ++ currentNode.name);
        ^currentNode.name
    }*/

/*    getCurrentPayload {
        ("Current payload: " ++ currentNode.payload).postln;
        this.mdlog(3, "CommandBuilder", "payload=" ++ currentNode.payload);
        ^currentNode.payload
    }*/

    isAtLeaf {
        ^currentNode.children.isEmpty
    }

/*    resetNavigation {
        currentNode = tree.root;
        fretPath = List[0];
        navigationComplete = false;  // important; reset the flag
        "🔄 Navigation reset".postln;
        this.mdlog(2, "CommandBuilder", "navigation reset");
        ^this
    }*/

//superseded
/*    printfretPath {
        ("Fret path: " ++ fretPath).postln;
        this.mdlog(3, "CommandBuilder", "fretPath=" ++ fretPath);
        ^this
    }*/

    // ---- Legacy shims (keep old tests working) ----

    // Old: listChildren -> New: printChildren
    listChildren {
        ^this.printChildren
    }

    // Old: navigateToChild(fret) OR navigateToChild(string, fret)
    navigateToChild { arg legacyArgA, legacyArgB = nil;
        var stringLevel, fretNumber;

        if (legacyArgB.isNil) {
            stringLevel = nil;
            fretNumber  = legacyArgA;
        }{
            stringLevel = legacyArgA;
            fretNumber  = legacyArgB;
        };

        ^this.navigateByFret(stringLevel, fretNumber)
    }

    // Old: printCurrentPath -> New: printPathToRoot
    printCurrentPath {
        ^this.printPathToRoot
    }

    // Old: getCurrentCommand -> New: getCurrentPayload
    getCurrentCommand {
        ^this.getCurrentPayload
    }

    // Old: reset -> New: resetNavigation
    reset {
        ^this.resetNavigation
    }

	// newer 20250924 ------
	printChildren {
    var childrenNames;

    if (currentNode.children.notEmpty) {
      currentNode.children.do({ arg item;
        // existing console output
        ("🎚️ Fret: " ++ item.fret ++ " → " ++ item.name).postln;
      });
      childrenNames = currentNode.children.collect(_.name);
      this.mdlog(3, "CommandBuilder", "children=" ++ childrenNames);
    } {
      "⚠️ No children".postln;
      this.mdlog(1, "CommandBuilder", "no children at node=" ++ currentNode.name);
    };
    ^childrenNames
  }

  navigateByFret { arg stringLevel, fretNumber;
    var nextNode;

    this.mdlog(2, "CommandBuilder", "🎸 navigateByFret: " ++ fretNumber
      ++ " (stringLevel=" ++ stringLevel ++ ")");

    nextNode = currentNode.getChildByFret(fretNumber);

    if (nextNode.notNil) {
      currentNode = nextNode;
      fretPath.add(currentNode.fret);
      ("Current node: " ++ currentNode.name).postln;
      this.mdlog(2, "CommandBuilder", "current=" ++ currentNode.name);
    } {
      ("⚠️ No child found for fret: " ++ fretNumber).postln;
      this.mdlog(1, "CommandBuilder", "no child for fret=" ++ fretNumber);
    };
    ^currentNode
  }

  navigateByName { arg stringLevel, childName;
    var nextNode;

    nextNode = currentNode.getChildByName(childName);

    if (nextNode.notNil) {
      currentNode = nextNode;
      fretPath.add(currentNode.fret);
      ("Current node: " ++ currentNode.name).postln;
      ("Path: " ++ currentNode.getFullPathString).postln;
      this.mdlog(2, "CommandBuilder", "current=" ++ currentNode.name);
      this.mdlog(3, "CommandBuilder", "path=" ++ currentNode.getFullPathString);
    } {
      var availableNames;
      availableNames = currentNode.children.collect(_.name).join(", ");
      ("⚠️ Available children: " ++ availableNames).postln;
      this.mdlog(1, "CommandBuilder", "not found; available=" ++ availableNames);
    };
    ^currentNode
  }

  printPathToRoot {
    currentNode.getPathToRoot.postln;
    this.mdlog(3, "CommandBuilder", "📍 path=" ++ currentNode.getPathToRoot);
    ^this
  }

  getCurrentName {
    currentNode.name.postln;
    this.mdlog(3, "CommandBuilder", "currentName=" ++ currentNode.name);
    ^currentNode.name
  }

  getCurrentPayload {
    ("Current payload: " ++ currentNode.payload).postln;
    this.mdlog(3, "CommandBuilder", "payload=" ++ currentNode.payload);
    ^currentNode.payload
  }

  resetNavigation {
    currentNode = tree.root;
    fretPath = List[0];
    navigationComplete = false;
    "🔄 Navigation reset".postln;
    this.mdlog(2, "CommandBuilder", "navigation reset");
    ^this
  }

  printfretPath {
    ("Fret path: " ++ fretPath).postln;
    this.mdlog(3, "CommandBuilder", "fretPath=" ++ fretPath);
    ^this
  }



}
