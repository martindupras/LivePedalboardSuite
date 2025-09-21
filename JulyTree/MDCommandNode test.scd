(
// Set a fixed random seed for reproducibility
thisThread.randSeed = 12345;

// Global node counter and limit
~nodeLimit = 50;
~nodeCount = 1;
~fixedChildren = 3;

// Create root node
~root = MDCommandNode.new("root", 0);

// Breadth-first queue
~nodeQueue = List[~root];

// Build tree
while {
    (~nodeQueue.notEmpty and: { ~nodeCount < ~nodeLimit })
} {
    var parent = ~nodeQueue.removeAt(0);
    ("Adding " ++ ~fixedChildren ++ " children to " ++ parent.name).postln;

    ~fixedChildren.do {
        if (~nodeCount < ~nodeLimit) {
            var childName = parent.name ++ "_" ++ ~nodeCount;
            var child = MDCommandNode.new(childName, ~nodeCount);
            parent.addChild(child);
            ~nodeQueue.add(child);
            ("Created node: " ++ child.name ++ " | Total nodes: " ++ ~nodeCount).postln;
            ~nodeCount = ~nodeCount + 1;
        };
    };
};

// Print tree
"Generated Tree Structure:".postln;
~root.printTreePretty("", true);

// Check integrity
"Running integrity check...".postln;
~root.checkIntegrity;

// Count total nodes
~countNodes = { |node|
    var count = 1;
    node.children.do { |c|
        count = count + ~countNodes.(c);
    };
    ^count;
};

("✅ Total nodes in tree: " ++ ~countNodes.(~root)).postln;
"Tree printed.".postln;
"end".postln;
)


b = MDCommandTree("root", 0);
