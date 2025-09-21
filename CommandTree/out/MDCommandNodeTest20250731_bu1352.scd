(
// 🧱 Declare all vars up front
var leafA, leafB, leafC, node1, node2, root;
var testNodeMethods;

// 🌿 Construct tree
leafA = MDCommandNode.new;
leafB = MDCommandNode.new;
leafC = MDCommandNode.new;
node1 = MDCommandNode.new;
node2 = MDCommandNode.new;
root = MDCommandNode.new;

node1.children = [leafA, leafB];       // node1 has two leaves
node2.children = [leafC];              // node2 has one leaf
root.children = [node1, node2];        // root has two intermediate nodes

// 🔍 Testing function for nodes
testNodeMethods = { |node, label|
    var isLeafVal, descCount, leafCount, depth;
    isLeafVal = node.isLeaf();
    descCount = node.countDescendants();
    leafCount = node.countLeavesOnly();  // if implemented
    depth = node.getDepth();

    (label ++ " →").postln;
    ("  isLeaf:           " ++ isLeafVal).postln;
    ("  countDescendants: " ++ descCount).postln;
    ("  countLeavesOnly:  " ++ leafCount).postln;
    ("  getDepth:         " ++ depth).postln;
    "---".postln;
};

// 🚀 Run tests
[
    testNodeMethods.(leafA, "Leaf A"),
    testNodeMethods.(node1, "Node 1"),
    testNodeMethods.(node2, "Node 2"),
    testNodeMethods.(root, "Root Node")
];
)
