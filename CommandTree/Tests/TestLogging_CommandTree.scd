// TestLogging_CommandTree.scd
// v0.1.3
// MD 20250923-0901

(
/*
Purpose
- Load the canonical CommandTree JSON used by LivePedalboardSystem.
- Print a useful summary: structure, counts, payload coverage, and (if present) sample command payloads.
- Validate and export a .tmp snapshot; list saved versions if available.

Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/

var jsonPrimary, jsonFallback, jsonPathUsed, tree, ok;
var totalNodes, leafCount, leavesAll, leavesWithPayload, payloadCoverage, payloadPctStr;
var findByName, commandsNode, haveCommands, samplePaths, tmpPath;

// logging
MDMiniLogger.get.setverbosity(3); // DEBUG
// canonical first, deprecated as fallback:
jsonPrimary  = Platform.userExtensionDir
    ++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";
jsonFallback = Platform.userExtensionDir
    ++ "/MDclasses/LivePedalboardSystem/MagicPedalboardCommandTree.json";

// choose path and report
jsonPathUsed = if(File.exists(jsonPrimary)) { jsonPrimary } { jsonFallback };
("JSON path → " ++ jsonPathUsed).postln;

// load
tree = MDCommandTree.new("root");
ok = tree.importJSONFile(jsonPathUsed);
("import ok → " ++ ok).postln;
if(ok.not) {
    "⚠️ Import failed; nothing to print. Check the path above.".warn;
    ^nil;
};

// normalize & tag
tree.assignPayloads; // payload=name where missing (leaves)
tree.root.tagByDepth(0);

// pretty print
"--- Tree (pretty) ---".postln;
tree.printTreePretty;

// counts
"--- Stats ---".postln;
totalNodes = tree.nodeMap.size;
leafCount  = tree.root.countLeavesOnly;
("nodes=" ++ totalNodes ++ "  leaves=" ++ leafCount).postln;

// payload coverage on leaves
leavesAll = List.new;
tree.nodeMap.values.do({ |n| if(n.isLeaf) { leavesAll.add(n) } });
leavesWithPayload = leavesAll.select({ |n| n.payload.notNil });
payloadCoverage = (leavesWithPayload.size.asFloat / (leavesAll.size.max(1).asFloat)) * 100.0;
payloadPctStr = (payloadCoverage.round(0.1)).asString ++ "%";
("payload coverage=" ++ leavesWithPayload.size ++ "/" ++ leavesAll.size
 ++ " (" ++ payloadPctStr ++ ")").postln;

// robust name lookup (supports findNodeByName / getNodeByName on tree or root)
findByName = { |nameString|
    var n;
    n = if(tree.respondsTo(\findNodeByName)) { tree.findNodeByName(nameString) } { nil };
    if(n.isNil and: { tree.respondsTo(\getNodeByName) }) { n = tree.getNodeByName(nameString) };
    if(n.isNil and: { tree.root.respondsTo(\findNodeByName) }) { n = tree.root.findNodeByName(nameString) };
    if(n.isNil and: { tree.root.respondsTo(\getNodeByName) }) { n = tree.root.getNodeByName(nameString) };
    n
};

// commands branch diagnostics
"--- Commands branch (if present) ---".postln;
commandsNode = findByName.("commands");
haveCommands = commandsNode.notNil;
("have 'commands' → " ++ haveCommands).postln;
if(haveCommands) {
    var leafStrings, visit;
    leafStrings = List.new;
    visit = { |node|
        if(node.isLeaf) {
            var p = node.payload ?? node.name;
            leafStrings.add(p.asString);
        } {
            node.children.do(visit);
        }
    };
    visit.value(commandsNode);
    samplePaths = leafStrings.copyTo(8); // first few for sanity
    ("sample payloads: " ++ samplePaths.asString).postln;
};

// validate & export a tmp (no Boolean test around return value)
tree.validateTree;
tmpPath = jsonPathUsed ++ ".tmp";
tree.exportJSONFile(tmpPath);
("exported → " ++ tmpPath).postln;

// versioned saves (if configured)
"--- Saved versions ---".postln;
tree.listSavedVersions;

"done.".postln;
)
