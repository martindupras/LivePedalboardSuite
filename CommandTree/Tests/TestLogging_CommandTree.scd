// TestLogging_CommandTree.scd
// v0.1.5
// MD 20250923-0936

(
/*
Purpose
- Load the canonical CommandTree JSON used by LivePedalboardSystem.
- Print a useful summary: structure, counts, payload coverage, and (if present) sample command payloads.
- Validate and export a .tmp snapshot; list saved versions if available.
- No early returns; no nonstandard List methods.

Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/

var jsonPrimary, jsonFallback, jsonPathUsed;
var tree, ok, proceed;
var totalNodes, leafCount, leavesAll, leavesWithPayload, payloadCoverage, payloadPctStr;
var findByName, commandsNode, haveCommands, samplePaths, tmpPath;
var showFirstN;

// verbosity for this test (ok to leave)
MDMiniLogger.get.setverbosity(3);

// choose path (prefer LivePedalboardSuite; fall back to MDclasses if present)
jsonPrimary  = Platform.userExtensionDir
    ++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";
jsonFallback = Platform.userExtensionDir
    ++ "/MDclasses/LivePedalboardSystem/MagicPedalboardCommandTree.json";
jsonPathUsed = if(File.exists(jsonPrimary)) { jsonPrimary } { jsonFallback };
("JSON path → " ++ jsonPathUsed).postln;

// load
tree = MDCommandTree.new("root");
ok = tree.importJSONFile(jsonPathUsed);
("import ok → " ++ ok).postln;
proceed = ok;

// helper: take first N from a List (safe)
showFirstN = { |listIn, nIn|
  var lim, out, i;
  lim = nIn ? 8;
  if(lim > listIn.size) { lim = listIn.size };
  out = List.new;
  i = 0;
  while({ i < lim }, {
    out.add(listIn[i]);
    i = i + 1;
  });
  out.asArray
};

// only continue if loaded
if(proceed) {
  // normalize & tag
  tree.assignPayloads;      // payload=name where missing
  tree.root.tagByDepth(0);

  // pretty tree
  "--- Tree (pretty) ---".postln;
  tree.printTreePretty;

  // stats
  "--- Stats ---".postln;
  totalNodes = tree.nodeMap.size;
  leafCount  = tree.root.countLeavesOnly;
  ("nodes=" ++ totalNodes ++ "  leaves=" ++ leafCount).postln;

  // payload coverage (leaves)
  leavesAll = List.new;
  tree.nodeMap.values.do({ |n| if(n.isLeaf) { leavesAll.add(n) } });
  leavesWithPayload = leavesAll.select({ |n| n.payload.notNil });
  payloadCoverage = (leavesWithPayload.size.asFloat / (leavesAll.size.max(1).asFloat)) * 100.0;
  payloadPctStr = (payloadCoverage.round(0.1)).asString ++ "%";
  ("payload coverage=" ++ leavesWithPayload.size ++ "/" ++ leavesAll.size
   ++ " (" ++ payloadPctStr ++ ")").postln;

  // robust name lookup across versions (tree/root; findNodeByName or getNodeByName)
  findByName = { |nameString|
    var n;
    n = if(tree.respondsTo(\findNodeByName)) { tree.findNodeByName(nameString) } { nil };
    if(n.isNil and: { tree.respondsTo(\getNodeByName) }) { n = tree.getNodeByName(nameString) };
    if(n.isNil and: { tree.root.respondsTo(\findNodeByName) }) { n = tree.root.findNodeByName(nameString) };
    if(n.isNil and: { tree.root.respondsTo(\getNodeByName) }) { n = tree.root.getNodeByName(nameString) };
    n
  };

  // commands branch diagnostic
  "--- Commands branch (if present) ---".postln;
  commandsNode = findByName.("commands");
  haveCommands = commandsNode.notNil;
  ("have 'commands' → " ++ haveCommands).postln;
  if(haveCommands) {
    var leafStrings, visit;
    leafStrings = List.new;
    visit = { |node|
      if(node.isLeaf) {
        leafStrings.add((node.payload ?? node.name).asString);
      }{
        node.children.do(visit);
      }
    };
    visit.(commandsNode);
    samplePaths = showFirstN.(leafStrings, 8);
    ("sample payloads: " ++ samplePaths.asString).postln;
  };

  // validate & export tmp
  tree.validateTree;
  tmpPath = jsonPathUsed ++ ".tmp";
  tree.exportJSONFile(tmpPath);
  ("exported → " ++ tmpPath).postln;

  // saved versions, if configured
  "--- Saved versions ---".postln;
  tree.listSavedVersions;

  "done.".postln;
}{
  ("⚠️ Import failed; nothing to print for " ++ jsonPathUsed).postln;
};
)
