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
 each node as a unique ID. That is achieved by increasing nodeCount in the sclang script. This needs to change to be held by the tree class.

*/

MDCommandNode {

	var <> name, <> id, <> parent, <> children, <> fret; // maybe add 'payload' or 'command''
	var <> depthTag; // to store the depth of the node. 0 is root. // in effect string


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
	createChild { |argName, argId, argFret|
		var child;
		child = getChildByName(argName);
		if (child.isNil) {
			// there's no child, create one
			child = MDCommandNode.new(argName, argId, argFret);
			this.addChild(child);
		}
		^child; // return child, which is a node
	}

	/* older version:
		createChild { |argName, argId, argFret|
		var existing;
		existing = children.detect { |c| c.name == argName };

		if (existing.isNil) {
			var newChild = MDCommandNode.new(argName, argId, argFret);
			this.addChild(newChild);
			^newChild; // VERY IMPORTANT! Many things were broken because of this
		}{
			^existing;
		};
	}
	*/

	//Not used because using getChildByName instead. But can use if clearer!
	childNameExists{ |argName|
		^children.any { |c| c.name == argName };
	}

	getChildByName { |argName|
		^children.detect { |c| c.name == argName };
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

	// thingIWantToDo {
	// 	| thingIwantToDoThingsTo | /*collection or number or something */
	// 	var answerSoFar = 0;
	// 	answerSoFar = answerSoFar + this.children.thingWeWantToDo;
	//
	// 	^answerSoFar;
	// }

}
