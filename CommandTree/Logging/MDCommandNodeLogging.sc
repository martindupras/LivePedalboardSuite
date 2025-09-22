MDCommandNodeLogging
v1.0.0
MD 2025-09-22 09:52 BST

/*
Purpose
- See file comments for details.
Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/


+ MDCommandNode {

    addChild { |child|
        if(child.isKindOf(MDCommandNode)) {
            child.parent = this;
            children.add(child);
            this.mdlog(2, "CommandNode", "➕ added child '" ++ child.name ++ "' under '" ++ name ++ "'");
        }{
            this.mdlog(1, "CommandNode", "⚠ attempted to add non-node child");
        };
        ^this
    }

    createChild { |name, id, fret|
        var child;
        if(name.isKindOf(String).not or: { id.isKindOf(Integer).not } or: { fret.isKindOf(Integer).not }) {
            this.mdlog(1, "CommandNode", "❌ invalid args for createChild");
            ^nil;
        };
        child = this.getChildByName(name);
        if(child.isNil) {
            child = MDCommandNode.new(name, id, fret);
            this.addChild(child);
            this.mdlog(2, "CommandNode", "✅ created '" ++ name ++ "' (id:" ++ id ++ " fret:" ++ fret ++ ")");
        }{
            this.mdlog(2, "CommandNode", "ℹ️ child already exists: " ++ name);
        };
        ^child
    }

    removeChildById { |idToRemove|
        var target = children.detect { |c| c.id == idToRemove };
        if(target.notNil) {
            children.remove(target);
            this.mdlog(2, "CommandNode", "🗑️ removed id " ++ idToRemove);
        }{
            this.mdlog(1, "CommandNode", "⚠ id not found: " ++ idToRemove);
        };
        ^this
    }

    getNodeByNamePath { |nameList|
        var currentLocal = this;
        nameList.do { |n|
            currentLocal = currentLocal.getChildByName(n);
            if(currentLocal.isNil) {
                this.mdlog(1, "CommandNode", "❌ path segment not found: " ++ n);
                ^nil;
            }
        };
        this.mdlog(2, "CommandNode", "✅ found node: " ++ currentLocal.name);
        ^currentLocal
    }

    printPathToRoot {
        this.mdlog(3, "CommandNode", "📍 " ++ this.getPathToRoot.join(" → "));
        ^this
    }

    printTreePretty { |level = 0, isLast = true, prefix = ""|
        var sortedChildren, connector, newPrefix, line;
        connector = if(level == 0) { "" } { if(isLast) { "└── " } { "├── " } };
        line = prefix ++ connector ++ this.name
            ++ " (fret:" ++ this.fret
            ++ ", id:" ++ this.id
            ++ ", payload:" ++ this.payload ++ ")";
        this.mdlog(3, "CommandNode", line);

        newPrefix = if(level == 0) { "" } { prefix ++ if(isLast) { "   " } { "│  " } };
        sortedChildren = this.children;
        sortedChildren.do { |child, i|
            var last = (i == (sortedChildren.size - 1));
            child.printTreePretty(level + 1, last, newPrefix);
        };
        ^this
    }
}
