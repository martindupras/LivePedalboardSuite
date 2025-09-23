// Editor_AddCommands_Branch_Canonical.scd
// v0.1.0
// MD 20250923-0906

(
/*
Purpose
- Ensure a minimal 'commands' branch exists in the canonical CommandTree JSON used by LivePedalboardSystem.
- Leaves get payloads equal to their names (e.g., "/add/delay", "/switch"), so they drive the adapter directly.

Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/

var jsonPath, tree, ok;
var ensureChildUnder, ensurePath, commandsNode, printSampleLeaves;

// canonical JSON path in LivePedalboardSuite:
jsonPath = Platform.userExtensionDir
  ++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";

// load
tree = MDCommandTree.new("root");
ok = tree.importJSONFile(jsonPath);
if(ok.not) {
  ("❌ Failed to load " ++ jsonPath).warn; ^nil;
};

// helper: ensure a named child exists under parent (idempotent)
ensureChildUnder = { |parentNode, childName, fretNumber|
  var existing, created;
  existing = parentNode.getChildByName(childName.asString);
  if(existing.notNil) { ^existing };
  created = tree.addNode(parentNode.id, childName.asString, fretNumber ? 1);
  if(created.isNil) { ("⚠️ addNode failed for " ++ childName).postln };
  ^created
};

// helper: ensure a whole path exists: ["commands","add","delay"], frets e.g. [10,1,1]
ensurePath = { |names, frets|
  var node, i, name, fret, count;
  node = tree.root;
  i = 0; count = names.size;
  while({ i < count }, {
    name = names[i];
    fret = frets[i] ? 1;
    node = ensureChildUnder.(node, name, fret);
    i = i + 1;
  });
  ^node
};

// 1) create commands branch and a minimal set of leaves (idempotent)
ensurePath.( ["commands"], [10] );
ensurePath.( ["commands","add","delay"],          [10,1,1] );
ensurePath.( ["commands","bypass","delay","on"],  [10,2,1,2] );
ensurePath.( ["commands","bypass","delay","off"], [10,2,1,3] );
ensurePath.( ["commands","switch"],               [10,3] );
ensurePath.( ["commands","setSource","testmelody"], [10,4,1] );

// 2) normalize payloads and tag depths
tree.assignPayloads;     // payload := name when missing
tree.root.tagByDepth(0);

// 3) save back to the canonical file
tree.exportJSONFile(jsonPath);
("✅ Updated commands branch in → " ++ jsonPath).postln;

// 4) print a short sample of command leaf payloads (sanity)
printSampleLeaves = {
  var start, visit, payloads;
  payloads = List.new;
  start = tree.root.getChildByName("commands");
  if(start.isNil) { "⚠️ 'commands' node still not found.".warn; ^nil };
  visit = { |n|
    if(n.isLeaf) {
      payloads.add((n.payload ?? n.name).asString);
    } {
      n.children.do(visit);
    }
  };
  visit.(start);
  ("sample payloads: " ++ payloads.copyTo(8).asString).postln;
};
printSampleLeaves.();
)
