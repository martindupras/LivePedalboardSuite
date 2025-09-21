// test_circularSaves20250826.scd
// MD



(
// Step 1: Load the latest saved tree version
~tree = MDCommandTree.new("root");
~loaded = ~tree.loadLatestVersion;

if (~loaded) {
    "Latest tree loaded.".postln;
    "Tree before modification:".postln;
    ~tree.printTreePretty;
} {
    "⚠️ No saved tree found. Starting with empty tree.".postln;
};
)

(
// Step 2: Save current version for comparison
~originalJSON = ~tree.saver.latestVersion;
)

(
// Step 3: Modify the tree
~newNode = ~tree.addNode(0, "NewNode", 99);

if (~newNode.notNil) {
    "New node added.".postln;
    ~tree.printTreePretty;
} {
    "⚠️ Failed to add new node.".postln;
};
)

(
// Step 4: Save the modified tree as a new version
~tree.saveVersioned;
)

(
// Step 5: Compare original and new JSON
~newJSON = ~tree.saver.latestVersion;

if (~originalJSON != ~newJSON) {
    "Change confirmed: tree content has been updated.".postln;
} {
    "⚠️ No change detected between versions.".postln;
};
)













// (
// // Step 1: Create a new tree
// ~tree = MDCommandTree.new("root");
//
// // Step 2: Add some nodes
// ~tree.addNode(0, "A", 1);
// ~tree.addNode(1, "B", 2);
// ~tree.addNode(2, "C", 3);
// "✅ Nodes added.".postln;
// ~tree.printTreePretty;
// )
//
// (
// // Step 3: Save the tree using CircularFileSave
// ~tree.saveVersioned;
// )
//
// (
// // Step 4: List saved versions
// ~tree.listSavedVersions;
// )
//
// (
// // Step 5: Load the latest saved version
// ~tree.loadLatestVersion;
// )
//
// (
// // Step 6: Print the tree to confirm it was restored
// "✅ Tree after loading latest version:".postln;
// ~tree.printTreePretty;
// )
