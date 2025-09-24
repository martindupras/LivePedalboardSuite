// MDCommandTree.sc
// v1.0.1
// MD 20250924-1022

MDCommandTree {
	var <>root, <>nodeLimit = 200, <>nodeCount = 0, <>nodeMap;
	var <>saver;

	*new { |rootName = "root", rootId = 0, nodeLimit|
		^super.new.init(rootName, rootId, nodeLimit);
	}


	*fromDict { |dict|
		var tree;

		// Use a default node limit, or extract from dict if available
		tree = MDCommandTree.new(dict[\name], dict[\id], dict[\nodeLimit] ?? 200);

		if (dict[\children].isKindOf(Array)) {
			dict[\children].do { |childDict|
				tree.rebuildTreeFromDict(childDict, tree.root);
			};
		};
		tree.root.payload = dict[\payload];

		^tree;
	}


	init { |rootName, rootId, limit|
		root = MDCommandNode.new(rootName, rootId);
		nodeLimit = limit;
		nodeCount = 1;

		nodeMap = IdentityDictionary.new(100);
		nodeMap.put(rootId, root);

		saver = CircularFileSave.new("myTree", "~/TreeSaves", 10); // this is what will manage saves

		^this
	}

	rebuildTreeFromDict { |dict, parent|
		var node;

		node = MDCommandNode.new(dict[\name], dict[\id], dict[\fret]);
		parent.addChild(node);

		nodeMap.put(node.id, node);
		nodeCount = node.id.max(nodeCount);

		if (dict[\children].isKindOf(Array)) {
			dict[\children].do { |childDict|
				this.rebuildTreeFromDict(childDict, node);
			};
		};

		node.payload = dict[\payload];

		^node;
	}

/*	printTreePretty {
		root.printTreePretty;
		^this;
	}*/

	tagDepths {
		root.tagByDepth(0);
		^this;
	}

	findNodeByName { |name|
		var found;
		found = nodeMap.values.detect { |node| node.name == name };
		if (found.notNil) {
			("🔍 Found node '" ++ found.name ++ "' at ID " ++ found.id).postln;
			^found
		} {
			"⚠️ Node not found".postln;
			^nil
		}
	}

	getNodeByNamePath { |nameList|
		var found;
		found = root.getNodeByNamePath(nameList);
		if (found.notNil) {
			^found
		} {
			("⚠️ Node not found at path: " ++ nameList.join(" → ")).postln;
			^nil
		}
	}

	addNode { |parentId, name, fret|
		var newId, parentNode, newNode;

		newId = nodeCount + 1;
		parentNode = nodeMap.at(parentId);

		if (parentNode.notNil) {
			nodeCount = newId;
			newNode = MDCommandNode.new(name, newId, fret);
			newNode.parent = parentNode;
			parentNode.addChild(newNode);
			nodeMap.put(newId, newNode);
			^newNode
		} {
			("⚠️ Invalid parent ID: " ++ parentId).postln;
			^nil
		}
	}

	removeNode { |nodeId|
		var nodeToRemove, parentNode, found;

		nodeToRemove = nodeMap.at(nodeId);
		parentNode = nodeToRemove.parent;

		if (parentNode.notNil) {
			found = parentNode.children.detect { |c| c === nodeToRemove };
			if (found.notNil) {
				parentNode.removeChildById(found.id);
				nodeMap.removeAt(nodeId);
				("🗑 Node " ++ nodeId ++ " removed.").postln;
				^nodeToRemove
			} {
				"⚠️ Node not found in parent's children".postln;
				^nil
			}
		} {
			"⚠️ Cannot remove root node".postln;
			^nil
		}
	}

	swapNodes { |nodeId1, nodeId2|
		var node1, node2, parent1, parent2;

		node1 = nodeMap.at(nodeId1);
		node2 = nodeMap.at(nodeId2);
		parent1 = node1.parent;
		parent2 = node2.parent;

		if (parent1.isNil or: { parent2.isNil }) {
			"⚠️ Both nodes must have parents to swap".postln;
			^nil
		};

		node1 = removeNode(nodeId1);
		node2 = removeNode(nodeId2);

		if (node1.isNil or: { node2.isNil }) {
			"⚠️ Failed to remove nodes for swapping".postln;
			^nil
		};

		parent1.addChild(node2);
		parent2.addChild(node1);

		"🔄 Nodes swapped".postln;
		^nil
	}

/*	exportJSONFile { |path|
		var jsonString, file;

		jsonString = JSONlib.convertToJSON(root.asDictRecursively);
		file = File(path, "w");

		if (file.isOpen) {
			file.write(jsonString);
			file.close;
			("📤 Tree exported to " ++ path).postln;
		} {
			"⚠️ Failed to open file for writing.".warn;
		}
	}*/

	// importJSONFile { |path|
	// 	var jsonString, dict, newTree;
	//
	// 	if (File.exists(path).not) {
	// 		"❌ File does not exist: %".format(path).postln;
	// 		^false;
	// 	};
	//
	// 	jsonString = File(path, "r").readAllString;
	//
	// 	if (jsonString.isNil or: { jsonString.isEmpty }) {
	// 		"⚠️ File is empty or unreadable.".postln;
	// 		^false;
	// 	};
	//
	// 	dict = JSONlib.convertToSC(jsonString);
	//
	// 	if (dict.isNil) {
	// 		"⚠️ Failed to parse JSON.".postln;
	// 		^false;
	// 	};
	//
	// 	newTree = MDCommandTree.fromDict(dict);
	// 	this.root = newTree.root;
	// 	this.nodeMap = newTree.nodeMap;
	// 	this.nodeCount = newTree.nodeCount;
	//
	// 	("📥 Tree imported from " ++ path).postln;
	// 	^true;
	// }

	// NEW - added to manage circular saves
/*	saveVersioned {
		var json = JSONlib.convertToJSON(root.asDictRecursively);
		saver.saveVersion(json);
		"Tree saved to versioned file.".postln;
	}*/
	//---

	// NEW - added to manage circular saves
/*	loadLatestVersion {
		var json = saver.latestVersion;
		var dict, newTree;

		if(json.isNil or: { json.isEmpty }) {
			"⚠️ No saved version found.".postln;
			^false;
		};

		dict = JSONlib.convertToSC(json);

		if(dict.isNil) {
			"⚠️ Failed to parse JSON.".postln;
			^false;
		};

		newTree = MDCommandTree.fromDict(dict);
		this.root = newTree.root;
		this.nodeMap = newTree.nodeMap;
		this.nodeCount = newTree.nodeCount;

		"📥 Tree loaded from latest version.".postln;
		^true;
	}*/
	//---

	// NEW - added to manage circular saves
	listSavedVersions {
		saver.listVersions;
	}

	//---




/*	validateTree {
		var seenNames = Set.new;
		var valid = true;
		nodeMap.values.do { |node|
			if (seenNames.includes(node.name)) {
				("⚠️ Duplicate node name: " ++ node.name).postln;
				valid = false;
			};
			seenNames.add(node.name);
		};
		^valid;
	}*/


	// THIS IS NEW. This is so that (for now) we can copy the name of the node into the payload instance variable.
	assignPayloads {
		var assignRecursively;

		assignRecursively = { |node|
			node.payload = node.name;
			node.children.do { |child|
				assignRecursively.(child);
			};
		};

		assignRecursively.(this.root);
		"🧠 Payloads assigned to all nodes in tree.".postln;
		^this;
	}

	printPayloads {
		var printRecursively;

		printRecursively = { |node, level = 0|
			var indent = "  " ! level;
			(indent.join ++ node.name ++ " → Payload: " ++ node.payload).postln;
			node.children.do { |child|
				printRecursively.(child, level + 1);
			};
		};

		printRecursively.(this.root);
		^this;
	}

  printTreePretty {
    root.printTreePretty;
    this.mdlog(3, "CommandTree", "pretty-print finished");
    ^this;
  }

  exportJSONFile { |path|
    var jsonString, file;

    jsonString = JSONlib.convertToJSON(root.asDictRecursively);
    file = File(path, "w");

    if (file.isOpen) {
      file.write(jsonString);
      file.close;
      ("📤 Tree exported to " ++ path).postln;
      this.mdlog(2, "CommandTree", "exported=" ++ path);
    } {
      "⚠️ Failed to open file for writing.".warn;
      this.mdlog(1, "CommandTree", "failed open for write: " ++ path);
    };
    ^this
  }

  importJSONFile { |path|
    var jsonString, dict, newTree;

    if (File.exists(path).not) {
      ("❌ File does not exist: %".format(path)).postln;
      this.mdlog(0, "CommandTree", "file does not exist: " ++ path);
      ^false;
    };

    jsonString = File(path, "r").readAllString;

    if (jsonString.isNil or: { jsonString.isEmpty }) {
      "⚠️ File is empty or unreadable.".postln;
      this.mdlog(1, "CommandTree", "empty/unreadable: " ++ path);
      ^false;
    };

    dict = JSONlib.convertToSC(jsonString);

    if (dict.isNil) {
      "⚠️ Failed to parse JSON.".postln;
      this.mdlog(0, "CommandTree", "failed to parse: " ++ path);
      ^false;
    };

    newTree = MDCommandTree.fromDict(dict);
    this.root     = newTree.root;
    this.nodeMap  = newTree.nodeMap;
    this.nodeCount= newTree.nodeCount;

    ("📥 Tree imported from " ++ path).postln;
    this.mdlog(2, "CommandTree", "imported=" ++ path);
    ^true;
  }

  saveVersioned {
    var jsonString;

    jsonString = JSONlib.convertToJSON(root.asDictRecursively);
    saver.saveVersion(jsonString);
    "Tree saved to versioned file.".postln;
    this.mdlog(2, "CommandTree", "versioned save complete");
  }

  loadLatestVersion {
    var jsonString, dict, newTree;

    jsonString = saver.latestVersion;

    if (jsonString.isNil or: { jsonString.isEmpty }) {
      "⚠️ No saved version found.".postln;
      this.mdlog(1, "CommandTree", "no saved version found");
      ^false;
    };

    dict = JSONlib.convertToSC(jsonString);

    if (dict.isNil) {
      "⚠️ Failed to parse JSON.".postln;
      this.mdlog(0, "CommandTree", "failed to parse saved JSON");
      ^false;
    };

    newTree = MDCommandTree.fromDict(dict);
    this.root     = newTree.root;
    this.nodeMap  = newTree.nodeMap;
    this.nodeCount= newTree.nodeCount;

    "📥 Tree loaded from latest version.".postln;
    this.mdlog(2, "CommandTree", "loaded latest version");
    ^true;
  }

  validateTree {
    var seenNames, validFlag;

    seenNames = Set.new;
    validFlag = true;

    nodeMap.values.do({ |nodeRef|
      if (seenNames.includes(nodeRef.name)) {
        ("⚠️ Duplicate node name: " ++ nodeRef.name).postln;
        this.mdlog(1, "CommandTree", "duplicate node name: " ++ nodeRef.name);
        validFlag = false;
      };
      seenNames.add(nodeRef.name);
    });

    this.mdlog(validFlag.if(2,0), "CommandTree",
      validFlag.if("✅ validation passed", "❌ validation failed"));

    ^validFlag;
  }
}
