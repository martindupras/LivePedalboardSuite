// MDCommandBuilder.sc

// MD 20250818

MDCommandBuilder {
	var <>tree, <>currentNode, <>currentCommand, <>fretPath;
	var <>navigationComplete = false;

	*new { |argTree| ^super.new.init(argTree); }

	init { |argTree|
		tree = argTree;
		currentNode = tree.root;
		fretPath = List[0];
		"CommandBuilder initialized".postln;
		^this
	}

	printChildren {
		var childrenNames;
		if (currentNode.children.notEmpty) {
			currentNode.children.do { |item|
				("🎚 Fret: " ++ item.fret ++ " → " ++ item.name).postln;
			};
			childrenNames = currentNode.children.collect(_.name);
		} {
			"⚠️ No children".postln;
		};
		^childrenNames
	}

	navigateByFret { |stringLevel, fretNumber|
		var nextNode;
		("🎸 Navigating by fret: " ++ fretNumber).postln;
		nextNode = currentNode.getChildByFret(fretNumber);
		if (nextNode.notNil) {
			currentNode = nextNode;
			fretPath.add(currentNode.fret);
			("Current node: " ++ currentNode.name).postln;
		} {
			("⚠️ No child found for fret: " ++ fretNumber).postln;
		};
		^currentNode
	}


	navigateByName { |stringLevel, childName|
		var nextNode = currentNode.getChildByName(childName);
		if (nextNode.notNil) {
			currentNode = nextNode;
			fretPath.add(currentNode.fret);
			("Current node: " ++ currentNode.name).postln;
			("Path: " ++ currentNode.getFullPathString).postln;
		} {
			("⚠️ Available children: " ++ currentNode.children.collect(_.name).join(", ")).postln;
		};
		^currentNode
	}

	printPathToRoot {
		currentNode.getPathToRoot.postln;
		^this
	}

	getCurrentName {
		currentNode.name.postln;
		^currentNode.name
	}

	getCurrentPayload {
		("Current payload: " ++ currentNode.payload).postln;
		//currentNode.payload.postln;
		^currentNode.payload
	}
	isAtLeaf {
		^currentNode.children.isEmpty;
	}

	resetNavigation {
		currentNode = tree.root;
		fretPath = List[0];
		navigationComplete = false;  // important; reset the flag!
		"🔄 Navigation reset".postln;
		^this
	}

	printfretPath {
		("Fret path: " ++ fretPath).postln;
		^this
	}

}
