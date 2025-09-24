// MDCommandNode.sc
// v1.0.1
// MD 20250924

MDCommandNode {
	var <>name, <>id, <>fret, <>parent, <>children;
	var <> payload; // the "command" that will be inserted in the tree


	*new { |name = "default", id = 1, fret = 1, parent = nil|
		^super.new.init(name, id, fret, parent);
	}

	init { |name, id, fret, parent = nil|
		this.name = name;
		this.id = id;
		this.fret = fret;
		this.parent = parent;
		//this.children = List.new; // updated to following:
		this.children = SortedList.new(nil, { |a, b| a.fret < b.fret });

		//if (children.isKindOf(List).not) updated to following:
		if (this.children.isKindOf(SortedList).not) {
			{
				("⚠️ Children is not a SortedList in node '" ++ name ++ "'! It is: " ++ children.class).postln;
			};

			^this
		}
	}

	// ───── Child Management ─────

	removeChildByName { |nameToRemove|
		var index = children.findIndex { |c| c.name == nameToRemove };
		if (index.notNil) { children.removeAt(index); }
	}


	// ───── Child Lookup ─────

	getChildByName { |name|
		if (name.isKindOf(String).not) {
			("❌ getChildByName error: name must be a String").warn;
			^nil;
		};
		^children.detect { |c| c.name == name }
	}

	getChildById { |id| ^children.detect { |c| c.id == id } }

	getChildByFret { |fret| ^children.detect { |c| c.fret == fret } }

	childNameExists { |name| ^children.any { |c| c.name == name } }

	// ───── Tree Navigation ─────

	getPathToRoot {
		var path = List.new;
		var current = this;
		while { current.notNil } {
			path.addFirst(current.name);
			current = current.parent;
		};
		^path
	}

	printPathToRoot {
		("📍 Path: " ++ this.getPathToRoot.join(" → ")).postln;
	}

	getNodeByNamePath { |nameList|
		var current = this;
		nameList.do { |name|
			current = current.getChildByName(name);
			if (current.isNil) {
				("❌ Node not found at path segment: " ++ name).postln;
				^nil;
			}
		};
		("✅ Found node: " ++ current.name).postln;
		^current
	}

	getDepth {
		^this.parent.notNil.if({ this.parent.getDepth + 1 }, { 0 })
	}

	// ───── Tree Analysis ─────

	isLeaf {
		^this.children.size == 0
	}


	hasChild { |node|
		^this.children.any { |c| c === node }
	}
	countDescendants {
		if (this.isLeaf) { ^1 } {
			^this.children.sum { |c| c.countDescendants }
		}
	}

	countLeavesOnly {
		^this.isLeaf.if({ 1 }, {
			this.children.sum { |c| c.countLeavesOnly }
		})
	}

	getFullPathString {
		^this.getPathToRoot.join(" → ");
	}

	//newer:
	checkIntegrity {
		var okType, failedChild;
		okType = this.children.isKindOf(List) or: { this.children.isKindOf(SortedList) };
		if(okType.not) {
			("❌ Integrity check failed at node '" ++ this.name
				++ "': children is " ++ children.class).postln;
			^false;
		};
		failedChild = this.children.detect { |c| c.checkIntegrity.not };
		if(failedChild.notNil) {
			("❌ Integrity failed in child: " ++ failedChild.name).postln;
			^false;
		};
		^true;
	}

	// ───── Tree Display ─────
	printTreePretty { |level = 0, isLast = true, prefix = ""|
		var sortedChildren, connector, newPrefix;

		// Print current node
		connector = if (level == 0) { "" } { if (isLast) { "└── " } { "├── " } };
		(prefix ++ connector ++ this.name ++
			" (fret: " ++ this.fret ++
			", id: " ++ this.id ++
			", payload: " ++ this.payload ++ ")").postln;

		// Prepare prefix for children
		newPrefix = if (level == 0) { "" } {
			prefix ++ if (isLast) { "    " } { "│   " }
		};

		// Use existing sortedChildren logic
		sortedChildren = this.children;

		// Recursively print children
		sortedChildren.do { |child, i|
			var last = (i == (sortedChildren.size - 1));
			child.printTreePretty(level + 1, last, newPrefix);
		};
	}

	// ───── Serialization for exporting ─────

	asDictRecursively {
		var childrenDicts;

		childrenDicts = this.children.collect({ arg childNode;
			childNode.asDictRecursively
		});

		^(
			id:       this.id,
			name:     this.name,
			fret:     this.fret,
			payload:  this.payload,    // ← Added: keep payload in exports
			children: childrenDicts
		)
	}

	addChild { arg child;
		if (child.isKindOf(MDCommandNode)) {
			child.parent = this;
			children.add(child);
			this.mdlog(2, "CommandNode", "➕ added child '" ++ child.name
				++ "' under '" ++ name ++ "'");
		} {
			"⚠️ Attempted to add a non-node child.".warn;
			this.mdlog(1, "CommandNode", "attempted to add non-node child");
		}
	}

	createChild { arg name, id, fret;
		var child;

		if (name.isKindOf(String).not or: { id.isKindOf(Integer).not } or: { fret.isKindOf(Integer).not }) {
			"❌ Invalid arguments for createChild".warn;
			this.mdlog(1, "CommandNode", "invalid args for createChild");
			^nil;
		};

		child = this.getChildByName(name);

		if (child.isNil) {
			child = MDCommandNode.new(name, id, fret);
			this.addChild(child);
			("✅ Created new child node: " ++ name
				++ " (ID: " ++ id ++ ", Fret: " ++ fret ++ ")").postln;
			this.mdlog(2, "CommandNode", "created '" ++ name
				++ "' (id:" ++ id ++ " fret:" ++ fret ++ ")");
		} {
			("ℹ️ Child node already exists: " ++ name).postln;
			this.mdlog(2, "CommandNode", "child already exists: " ++ name);
		};

		^child
	}

	removeChildById { arg idToRemove;
		var childToRemove;

		childToRemove = children.detect({ arg nodeRef; nodeRef.id == idToRemove });

		if (childToRemove.notNil) {
			children.remove(childToRemove);
			"🗑 Child removed".postln;
			this.mdlog(2, "CommandNode", "removed id=" ++ idToRemove);
		} {
			"⚠️ ID not found".postln;
			this.mdlog(1, "CommandNode", "id not found: " ++ idToRemove);
		}
	}
}
