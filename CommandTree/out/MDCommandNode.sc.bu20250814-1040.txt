// MDCommandNode.sc
// Refactored for clarity and correctness
// MD 20250813

MDCommandNode {
    var <>name, <>id, <>fret, <>parent, <>children;
    var <>depthTag;

    *new { |name = "default", id = 1, fret = 1, parent = nil|
        ^super.new.init(name, id, fret, parent);
    }

    init { |name, id, fret, parent = nil|
        this.name = name;
        this.id = id;
        this.fret = fret;
        this.parent = parent;
        this.children = List.new;

        if (children.isKindOf(List).not) {
            ("⚠️ Children is not a List in node '" ++ name ++ "'! It is: " ++ children.class).postln;
        };

        ^this
    }

    // ───── Child Management ─────

    addChild { |child|
        if (child.isKindOf(MDCommandNode)) {
            child.parent = this;
            children.add(child);
        } {
            "⚠️ Attempted to add a non-node child.".warn;
        }
    }

    createChild { |name, id, fret|
        var child;
        if (name.isKindOf(String).not or: { id.isKindOf(Integer).not } or: { fret.isKindOf(Integer).not }) {
            ("❌ Invalid arguments for createChild").warn;
            ^nil;
        };

        child = this.getChildByName(name);
        if (child.isNil) {
            child = MDCommandNode.new(name, id, fret);
            this.addChild(child);
            ("✅ Created new child node: " ++ name ++ " (ID: " ++ id ++ ", Fret: " ++ fret ++ ")").postln;
        } {
            ("ℹ️ Child node already exists: " ++ name).postln;
        };

        ^child
    }

    removeChildByName { |nameToRemove|
        var index = children.findIndex { |c| c.name == nameToRemove };
        if (index.notNil) { children.removeAt(index); }
    }

    removeChildById { |idToRemove|
        var childToRemove = children.detect { |c| c.id == idToRemove };
        if (childToRemove.notNil) {
            children.remove(childToRemove);
            ("🗑 Child removed").postln;
        } {
            ("⚠️ ID not found").postln;
        }
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

    tagByDepth { |depth|
        this.depthTag = depth;
        this.children.do { |c| c.tagByDepth(depth + 1) };
    }

    // ───── Tree Analysis ─────

    isLeaf {
        ^this.children.size == 0
    }

    isDescendant { |node|
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

	checkIntegrity {
		var failedChild;

		if (this.children.isKindOf(List).not) {
			("❌ Integrity check failed at node '" ++ this.name ++ "'").postln;
			^false;
		};

		failedChild = this.children.detect { |c| c.checkIntegrity.not };
		if (failedChild.notNil) {
			("❌ Integrity failed in child: " ++ failedChild.name).postln;
			^false;
		};

		^true
	}




    // ───── Tree Display ─────

    printTreePretty { |level = 0, isLast = true|
        var indent, branch, line;

        indent = Array.fill(level, { |i|
            if (i == (level - 1)) {
                if (isLast) { "    " } { "│   " };
            } {
                "    ";
            }
        }).join("");

        branch = if (level > 0) {
            if (isLast) { "└── " } { "├── " };
        } { "" };

        line = indent ++ branch ++ this.name ++ " (ID: " ++ this.id ++ ", Fret: " ++ this.fret ++ ")";
        line.postln;

        this.children.do { |child, i|
            child.printTreePretty(level + 1, i == (this.children.size - 1));
        }
    }

    // ───── Serialization ─────

    asDictRecursively {
        ^(
            id: this.id,
            name: this.name,
            fret: this.fret,
            children: this.children.collect { |c| c.asDictRecursively }
        )
    }
}






//older version

/*

// MDCommandNode.sc
// MD20250724
// updated 20250804

// Recoded to be clearer and more structured.
/*
This class is for a single node in the tree.
It is meant be used with MDCommandTree

One node represents a branch or leaf in the tree.
name (for now) is both the name of the node and the command it represents
children is a list that contains references to the branches below it.
depthTag is the depth in the tree; correlated to the guitar string number.

Notes:
each node has a unique ID. That is achieved by increasing nodeCount in the sclang script. This needs to change to be held by the tree class.

*/

MDCommandNode {

	var <> name, <> id, <> parent, <> children, <> fret; // maybe add 'payload' or 'command''
	var <> depthTag; // to store the depth of the node. 0 is root. // in effect string // APPARENTLY STUPID. REMOVE.


	// default arguments probably never used, but just in case. Note that the only node without a parent should be the root.

	*new { |name = "default", id = 1, fret = 1, parent = nil|
		^super.new.init(name, id, fret, parent)
	}

	init { |argName, argId, argFret, argParent = nil|
		this.name = argName;
		this.id = argId;
		this.fret = argFret;
		this.parent = argParent;
		this.children = List.new; // The children are held in a list. NOT ORDERED.
		// turn to TRUE to display:
		if (false) {("Created node '" ++ name ++ "' with id " ++ id).postln;};

		if (this.children.isKindOf(List).not) {
			("Children is not a List in node '" ++ name ++ "'! It is: " ++ this.children.class).postln;
		};

		^this // return a node
	}

	// Used in createChild
	addChild { |child|
		if (child.isKindOf(MDCommandNode)) {
			child.parent = this;
			children.add(child);
		} {
			"Attempted to add a non-node child.".warn;
		}
	}

	removeChildByName { |nameToRemove|
		var index = children.findIndex { |c| c.name == nameToRemove };
		if (index.notNil) {
			children.removeAt(index);
		};
	}

	removeChildById { |argId|
		var childToRemove = children.detect { |c| c.id == argId };
		if (childToRemove.notNil) {
			this.children.remove(childToRemove);
			("Child removed").postln;
		}{
			("ID not found").postln;
		};
	}

	// revised after talking with SH/PM
	// now with lots of added error checking 20250813-1233
	createChild { |argName, argId, argFret|
		var child;

		if (argName.isKindOf(String).not) {
			("❌ createChild error: argName must be a String, got " ++ argName.class).warn;
			^nil;
		};

		if (argId.isKindOf(Integer).not) {
			("❌ createChild error: argId must be an Integer, got " ++ argId.class).warn;
			^nil;
		};

		if (argFret.isKindOf(Integer).not) {
			("❌ createChild error: argFret must be an Integer, got " ++ argFret.class).warn;
			^nil;
		};

		child = this.getChildByName(argName);

		if (child.isNil) {
			child = MDCommandNode.new(argName, argId, argFret);
			this.addChild(child);
			("✅ Created new child node: " ++ argName ++ " (ID: " ++ argId ++ ", Fret: " ++ argFret ++ ")").postln;
		} {
			("ℹ️ Child node already exists: " ++ argName).postln;
		};

		^child;
	}


	//Not used because using getChildByName instead. But can use if clearer!
	childNameExists{ |argName|
		^children.any { |c| c.name == argName };
	}
	// new with lots of error checking:
	getChildByName { |argName|
		var found;
		if (argName.isKindOf(String).not) {
			("❌ getChildByName error: argName must be a String, got " ++ argName.class).warn;
			^nil;
		};

		found = children.detect { |c| c.name == argName };

		if (found.isNil) {
			("🔍 getChildByName: No child found with name '" ++ argName ++ "'").postln;
		} {
			("🔍 getChildByName: Found child '" ++ argName ++ "'").postln;
		};

		^found;
	}


	// SEEMS WORKING!
	getChildById { |argID|
		^children.detect { |c| c.id == argID };
	}

	//SEEMS WORKING
	getChildByfret { |argFret|
		postln("Inside get child by fret")
		^children.detect { |c| c.fret == argFret };
	}

	getPathToRoot {
		var path = List.new;
		var current = this;
		while {current.notNil} {
			path.addFirst(current.name);
			current = current.parent;
		};
		^path
	}

	printPathToRoot {
		("Path: " ++ this.getPathToRoot.join(" → ")).postln;
	}

	getPathString {
		^this.getPathToRoot.join(" -> ");
	}

	// find child -- is this ever used?
	findChild{
		|argFret|
		^children[argFret];
	}


	getNodeByNamePath{
		|argPathList| // we have a list of names
		var current;
		current = this;
		argPathList.do { |item, i|
			current = current.children.detect{|c| c.name == item};
			if (current.isNil) {
				postln("not found");
				^nil;
			}
		};
		postln("Found:"+current.name);
		^current;
	}


	isDescendant{
		|argNode|
		var found;
		found = this.children.detect {|c| c === argNode};
		if (found.notNil)
		{postln("Child found");
			^true
		}{
			postln("not found");
			^false
		}
	}

	isLeaf{
		if(this.children.size <= 0)
		{
			^true
		}{
			^false
		}


		// could condense to just:
		//^this.children.size <= 0;
	}

	countDescendants{
		var count = 0;
		if (this.isLeaf()) {
			count = 1;
		}{
			this.children.do {
				|c|
				count = count + c.countDescendants;
			}
		}
		^count;
	}
	// done by Copilot for me. Not needed now but might come in handy.
	countLeavesOnly {
		^this.isLeaf().if({ 1 }, {
			this.children.sum { |c| c.countLeavesOnly }
		});
	}

	getDepth{
		// traverse upward, counting along the way, until we get to root
		if (this.parent.notNil){
			^this.parent.getDepth + 1;
		}{
			^0
		}
	}

	tagByDepth{
		|argDepth|
		this.depthTag = argDepth;
		this.children.do {
			|c| c.tagByDepth(argDepth+1) ;
		}
	}

	checkIntegrity {
		var result, allGood;
		("🔍 Checking node: " ++ name).postln;

		if (children.isKindOf(List).not) {
			("❌ Integrity check failed at node '" ++ name ++ "': children is " ++ children.class).postln;
			^false;
		};

		allGood = true;

		children.do { |child|
			result = child.checkIntegrity;
			if (result.not) {
				allGood = false;
			};
		};

		^allGood;
	}


	// NOW WORKING... at last.
	printTreePretty { |level=0, isLast=true|
		// level: 0 is root
		// isLast: boolean
		// indent: String (.join converts array to string)
		// branch: stores the glyph
		// line: the line that will get printed with the indent, branch, name of the node, id and fret
		var indent, branch, childIsLast, line;

		// At each level (root = 0) we draw either
		//    a vertical bar if previous node isn't last
		//    spacing if last sibling or root
		indent = Array.fill(level, { |i|
			if (i == (level - 1)) {
				if (isLast) { "    " } { "│   " };
			} {
				"    ";
			}
		}).join("");
		//DEBUG
		//postln("indent.class:"+indent.class);

		// ├──  if node has siblings after it
		// └──  if node is the last sibling
		// ""   if it's the root
		branch = if (level > 0) {
			if (isLast) { "└── " } { "├── " };
		} { "" };

		//print indent, branch marker and name on one line (for one node)
		//(indent ++ branch ++ name).postln;

		line = 	indent ++ branch ++ name ++ " (ID: " ++ id ++ ", Fret: " ++ fret ++")";
		line.postln;


		// recursively do the same for each child
		// check if child is last to pass as input argument to printTreePretty in recursion
		children.do { |child, i|
			childIsLast = (i == (children.size - 1));
			child.printTreePretty(level + 1, childIsLast);
		};
	}


	asDictRecursively {
		^(
			id: this.id,
			name: this.name,
			fret: this.fret,
			children: this.children.collect { |child|
				child.asDictRecursively
			}
		)
	}


}
*/