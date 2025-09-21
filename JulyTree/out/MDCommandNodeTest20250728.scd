// MDCommandNodeTest20250728.scd


(
var root = MDCommandNode.new("root", 0);
var a = root.createChild("a", 1, 1);
var b = root.createChild("b", 2, 1);

a.createChild("c", 3, 1);
a.createChild("d", 4, 1);
b.createChild("e", 5, 1);

// Audit structure
("Children of root: " ++ root.children.collect(_.name)).postln;
("Children of a: " ++ a.children.collect(_.name)).postln;
("Children of b: " ++ b.children.collect(_.name)).postln;

root.printTreePretty;
)

/////////////////

(
var tree, root, a, b;

// Create tree manager
tree = MDCommandTree.new;
tree.nodeMap = IdentityDictionary.new;
tree.nodeCount = 0;

// Create root node and register it
root = MDCommandNode.new("root", 0, 0);
tree.nodeMap.put(0, root);

// Add nodes using safe syntax
a = tree.addNode(0, "a", 1);
b = tree.addNode(0, "b", 1);

// Optional: continue only if valid
if (a.notNil) {
    tree.addNode(a.id, "c", 1);
    tree.addNode(a.id, "d", 1);
};
if (b.notNil) {
    tree.addNode(b.id, "e", 1);
};

// Audit and print
("Children of root: " ++ root.children.collect(_.name)).postln;
("Children of a: " ++ (a.notNil.if { a.children.collect(_.name) } { "❌ 'a' missing" })).postln;
("Children of b: " ++ (b.notNil.if { b.children.collect(_.name) } { "❌ 'b' missing" })).postln;

("Tree:").postln;
root.printTreePretty;

"".postln;
"Tree class:".postln;
tree.class;

tree.removeNode(5);
tree.swapNodes;
)

