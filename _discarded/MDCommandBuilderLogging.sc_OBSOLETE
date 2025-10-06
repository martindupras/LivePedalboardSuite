// MDCommandBuilderLogging
// v1.0.0
// MD 2025-09-22 09:52 BST

/*
Purpose
- See file comments for details.
Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/


+ MDCommandBuilder {

    printChildren {
        var names;
        if(currentNode.children.notEmpty) {
            currentNode.children.do { |item|
                this.mdlog(3, "CommandBuilder", "🎚 fret " ++ item.fret ++ " → " ++ item.name);
            };
            names = currentNode.children.collect(_.name);
        }{
            this.mdlog(1, "CommandBuilder", "⚠ no children");
            names = [];
        };
        ^names
    }

    navigateByFret { |stringLevel, fretNumber|
        var nextNode;
        this.mdlog(2, "CommandBuilder", "🎸 navigateByFret: " ++ fretNumber);
        nextNode = currentNode.getChildByFret(fretNumber);
        if(nextNode.notNil) {
            currentNode = nextNode;
            fretPath.add(currentNode.fret);
            this.mdlog(2, "CommandBuilder", "current=" ++ currentNode.name);
        }{
            this.mdlog(1, "CommandBuilder", "⚠ no child for fret " ++ fretNumber);
        };
        ^currentNode
    }

    navigateByName { |stringLevel, childName|
        var nextNode = currentNode.getChildByName(childName);
        if(nextNode.notNil) {
            currentNode = nextNode;
            fretPath.add(currentNode.fret);
            this.mdlog(2, "CommandBuilder", "current=" ++ currentNode.name);
            this.mdlog(3, "CommandBuilder", "path=" ++ currentNode.getFullPathString);
        }{
            var avail = currentNode.children.collect(_.name).join(", ");
            this.mdlog(1, "CommandBuilder", "⚠ not found; available: " ++ avail);
        };
        ^currentNode
    }

    printPathToRoot {
        this.mdlog(3, "CommandBuilder", "📍 path=" ++ currentNode.getPathToRoot);
        ^this
    }

    getCurrentName {
        this.mdlog(3, "CommandBuilder", "currentName=" ++ currentNode.name);
        ^currentNode.name
    }

    getCurrentPayload {
        this.mdlog(3, "CommandBuilder", "payload=" ++ currentNode.payload);
        ^currentNode.payload
    }

    resetNavigation {
        currentNode = tree.root;
        fretPath = List[0];
        navigationComplete = false;
        this.mdlog(2, "CommandBuilder", "🔄 navigation reset");
        ^this
    }

    printfretPath {
        this.mdlog(3, "CommandBuilder", "fretPath=" ++ fretPath);
        ^this
    }
}
