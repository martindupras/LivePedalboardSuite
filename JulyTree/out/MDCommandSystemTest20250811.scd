// MDCommandSystemTest20250804.scd
// update 20250811
// addiing changing |fret| to |string, fret| in navigateToChild methods

// MD 20250804

// This is the testing code to test various aspects of the tree. This is just for testing, it does not do anything really useful yet other than invoke most methods.

////////////////////////////////////////////////////////////////////
// [1] Run this block to create a tree structure with data in it
///////////////////////////////////////////////////////////////////

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
node3 = tree.addNode(tree.getNodeByName("root").id, "names", 7);
 leaf3A = tree.addNode(tree.getNodeByName("names").id, "sends", 2);
 leaf4A = tree.addNode(tree.getNodeByName("names").id, "receive", 4);
//
node4 = tree.addNode(tree.getNodeByName("root").id, "values", 9);
 leaf4A = tree.addNode(tree.getNodeByName("values").id, "10", 9);
 leaf4B = tree.addNode(tree.getNodeByName("values").id, "100", 10);
 leaf4C = tree.addNode(tree.getNodeByName("values").id, "10", 11);
 leaf4D = tree.addNode(tree.getNodeByName("values").id, "100", 12);

// Tag all nodes with depth
tree.root.tagByDepth(0);
"----- Depth:".postln;
tree.root.depthTag;
"-----".postln;

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


// Export
tree.exportJSONFile("~/Command Tree savefiles/myTree.json".standardizePath);

// Import
tree.importJSONFile("~/Command Tree savefiles/myTree.json".standardizePath);

)

////////////////////////////////////////////////////////////////////
// [2] Now run these line and watch the console
///////////////////////////////////////////////////////////////////

// Setup
~builder = MDCommandBuilder.new(~tree);
~queue = MDCommandQueue.new;

// Explore
~builder.listChildren;
~builder.getDepth;
// what is the string
~builder.navigateToChild(6,3); // string 6 fret 3, branch A
~builder.listChildren;
~builder.navigateToChild(5,7); // e.g. Twig A1b
~builder.printCurrentPath;

~builder.getCurrentCommand;
// Add to queue
~queue.addCommand(~builder.getCurrentCommand);

~builder.reset; // we need this to start at root again

// Explore
~builder.listChildren;
~builder.navigateToChild(6,9); // e.g. Branch A
~builder.listChildren;
~builder.navigateToChild(5,12); // e.g. Twig A1b
~builder.printCurrentPath;

~builder.getCurrentCommand;
// Add to queue
~queue.addCommand(~builder.getCurrentCommand);

// Export
~queue.queue.postln; // To inspect queue contents directly
~queue.exportToEnv;

~commandToSend;
~commandToSend = nil;

