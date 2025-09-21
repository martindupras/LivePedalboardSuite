// MDCommandNodeLegacy.sc
// MD20250724

// recoding to be more structured and better understood.
/*
This class is for a single node in the tree.
instance variables:
  name
  id (for lookup and operations on nodes)
  parent: reference to the parent
  list of children nodes (we settled on nodes)

instance methods:
   addChild
   removeChildByName
   removeChildById
   getChildByName
   getChildById
   getPathToRoot
   getPathString
temp: checkIntegrity (given by copilot)
   printTreePretty (given by copilot)


*/


/*
Notes:
 each node as a unique ID. That is achieved by increasing nodeCount in the sclang script. This needs to change to be held by the tree class.

*/


MDCommandNodeLegacy {

	var <>name, <>id, <>parent, <>children;

	*new { |name = "default", id = 1, parent = nil|
		^super.new.init(name, id, parent)
	}

	init { |argName, argId, argParent = nil|
		this.name = argName;
		this.id = argId;
		this.parent = argParent;
		this.children = List.new;

		("INIT: Created node '" ++ name ++ "' with id " ++ id).postln;

		if (this.children.isKindOf(List).not) {
			("INIT ERROR: children is not a List in node '" ++ name ++ "'! It is: " ++ this.children.class).postln;
		};

		^this
	}

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

	createChild { |argName, argId|
		var existing = children.detect { |c| c.name == argName };
		if (existing.isNil) {
			var newChild = MDCommandNode.new(argName, argId, this);
			children.add(newChild);
		};
	}

	getChildByName { |argName|
		^children.detect { |c| c.name == argName };
	}

	getChildById { |argID|
		^children.detect { |c| c.id == argID };
	}

	getPathToRoot {
		var path = List.new;
		var current = this;
		while (current.notNil) {
			path.addFirst(current.name);
			current = current.parent;
		};
		^path
	}

	getPathString {
		^this.getPathToRoot.join(" -> ");
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



	printTreePretty { |indent = "", isLast = true|
		var prefix, newIndent, childCount, childIsLast;

		prefix = indent ++ (isLast.if { "└── " } { "├── " });
		(prefix ++ name).postln;

		if (children.isKindOf(List).not) {
			("❌ ERROR: Node '" ++ name ++ "' has invalid children: " ++ children).postln;
			^this;
		};

		childCount = (children.isKindOf(List).if { children.size } { 0 });

		if (childCount == 0) { ^this };  // Exit early if no children

		newIndent = indent ++ (isLast.if { "    " } { "│   " });

		for (0, childCount - 1, { |index|
			var child = children[index];
			childIsLast = (index == (childCount - 1));
			child.printTreePretty.(newIndent, childIsLast);
		});
	}

}
