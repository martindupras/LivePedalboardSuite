(
// Build a tree for testing
var tree, root;
var node1, node2, node3, node4;
var leaf1A, leaf1B, leaf2A, leaf2B, leaf3A, leaf3B, leaf4A, leaf4B, leaf4C, leaf4D;
var testNodeMethods, printTreeSummary;

// Create tree
tree = MDCommandTree.new("root", 0, 50);
root = tree.root;

// Add intermediate nodes to root
node1 = tree.addNode(tree.getNodeByName("root").id, "audio", 3);
 leaf1A = tree.addNode(tree.getNodeByName("audio").id, "noise", 7);
leaf1B = tree.addNode(tree.getNodeByName("audio").id, "oscillators", 9);
//
node2 = tree.addNode(tree.getNodeByName("root").id, "control", 5);
 leaf2A = tree.addNode(tree.getNodeByName("control").id, "LFO", 7);
 leaf2B = tree.addNode(tree.getNodeByName("control").id, "gate", 9);
//
node3 = tree.addNode(tree.getNodeByName("root").id, "names", 3);
 leaf3A = tree.addNode(tree.getNodeByName("names").id, "sends", 11);
 leaf4A = tree.addNode(tree.getNodeByName("names").id, "receive", 7);
//
node4 = tree.addNode(tree.getNodeByName("root").id, "values", 5);
 leaf4A = tree.addNode(tree.getNodeByName("values").id, "10", 9);
 leaf4B = tree.addNode(tree.getNodeByName("values").id, "100", 11);
 leaf4C = tree.addNode(tree.getNodeByName("values").id, "10", 9);
 leaf4D = tree.addNode(tree.getNodeByName("values").id, "100", 11);


// Tag all nodes with depth
tree.root.tagByDepth(0);

// 📋 Node Testing Function
testNodeMethods = { |node, label|
    var isLeafVal, descCount, leafCount, depth, depthTag;
    isLeafVal = node.isLeaf();
    descCount = node.countDescendants();
    leafCount = node.countLeavesOnly();
    depth = node.getDepth();      // computed recursively
    depthTag = node.depthTag;    // stored via tagByDepth

    (label ++ " →").postln;
    ("  isLeaf:           " ++ isLeafVal).postln;
    ("  countDescendants: " ++ descCount).postln;
    ("  countLeavesOnly:  " ++ leafCount).postln;
    ("  getDepth:         " ++ depth).postln;
    ("  depthTag:         " ++ depthTag).postln;
    "---".postln;
};

// Tree Summary Function
printTreeSummary = {
    tree.nodeMap.values.do { |node|
        testNodeMethods.(node, node.name);
    };
};

// Run tests
printTreeSummary.();
"-----".postln;
tree.printTreePretty;
"-----".postln;

~tree = tree;

)



/////////////////////
/// BUILD A TREE - older version.
/////////////////////

(
// Setup
var tree, root, lvl1A, lvl1B, lvl2A, lvl2B, lvl3A, lvl3B, lvl3C;
var printSummary;

// 🌱 Initialize tree and root
tree = MDCommandTree.new("root", 0, 1);
root = tree.root;

// 🧩 Level 1
lvl1A = tree.addNode(root.id, "Branch A", 2);
lvl1B = tree.addNode(root.id, "Branch B", 3);

// 🧩 Level 2
lvl2A = tree.addNode(lvl1A.id, "SubBranch A1", 4);
lvl2B = tree.addNode(lvl1B.id, "SubBranch B1", 5);

// 🧩 Level 3
lvl3A = tree.addNode(lvl2A.id, "Twig A1a", 6);
lvl3B = tree.addNode(lvl2A.id, "Twig A1b", 7);
lvl3C = tree.addNode(lvl2B.id, "Twig B1a", 8);

// 🏷️ Tag depth from root
tree.root.tagByDepth(0);

// 📋 Node Summary
printSummary = {
    tree.nodeMap.values.do { |node|
        (node.name ++ " → depthTag: " ++ node.depthTag ++ ", getDepth: " ++ node.getDepth).postln;
    };
};

// 🖼️ Print results
printSummary.();
tree.printTreePretty;

tree.getNodeByName("Twig A1b").printPathToRoot;

)
