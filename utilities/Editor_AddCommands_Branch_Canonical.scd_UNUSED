// Editor_AddCommands_Branch_Canonical.scd
// v0.1.7
// MD 20250923-0956

(
/*
Purpose
- Ensure a minimal 'commands' branch exists in the canonical CommandTree JSON used by LivePedalboardSystem.
- Set each leaf's payload under 'commands' to a canonical path string ("/verb/arg/...").
- Uses only known-good methods; no caret returns; var-first at top-level.

Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/

var jsonPath, tree, ok, proceed;
var findChildByName, ensureChildUnder, ensurePath;
var commandsNode, printSampleLeaves, showFirstN;
var setCanonicalPayloads, buildPathsDown, buildPathFromSegments, rootCmd, count;

// ── entry banner ─────────────────────────────────────────────────────────────
"──────────────────────────────────────────────────────────────────────────────".postln;
"Editor_AddCommands_Branch_Canonical: ENTER".postln;

// ── canonical JSON path (LivePedalboardSuite) ────────────────────────────────
jsonPath = Platform.userExtensionDir
  ++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";
("JSON path → " ++ jsonPath).postln;

// ── load tree ────────────────────────────────────────────────────────────────
tree = MDCommandTree.new("root");
ok = tree.importJSONFile(jsonPath);
("import ok → " ++ ok).postln;
proceed = ok;

// ── helpers (only stable fields/methods) ─────────────────────────────────────
findChildByName = { |parentNode, childName|
  var wanted, found;
  wanted = childName.asString;
  found = nil;
  parentNode.children.do({ |c|
    if(c.name.asString == wanted) { found = c };
  });
  found
};

ensureChildUnder = { |parentNode, childName, fretNumber|
  var existing, created, fret;
  fret = fretNumber ? 1;
  existing = findChildByName.(parentNode, childName);
  if(existing.notNil) {
    existing
  }{
    created = tree.addNode(parentNode.id, childName.asString, fret);
    if(created.isNil) { ("⚠️ addNode failed for " ++ childName).postln };
    created
  }
};

ensurePath = { |names, frets|
  var node, i, count, name, fret;
  node = tree.root;
  i = 0; count = names.size;
  while({ i < count }, {
    name = names[i];
    fret = frets[i] ? 1;
    node = ensureChildUnder.(node, name, fret);
    i = i + 1;
  });
  node
};

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

// ── do the work only if load succeeded ───────────────────────────────────────
if(proceed) {
  // 1) ensure 'commands' branch + minimal leaves (idempotent)
  ensurePath.( ["commands"], [10] );
  ensurePath.( ["commands","add","delay"],            [10,1,1] );
  ensurePath.( ["commands","bypass","delay","on"],    [10,2,1,2] );
  ensurePath.( ["commands","bypass","delay","off"],   [10,2,1,3] );
  ensurePath.( ["commands","switch"],                 [10,3] );
  ensurePath.( ["commands","setSource","testmelody"], [10,4,1] );

  // 2) normalize payloads and tag depths
  tree.assignPayloads;     // payload := name where missing
  tree.root.tagByDepth(0);

  // 2b) set canonical path strings for each 'commands' leaf ("/verb/arg/...")
  buildPathFromSegments = { |segs|
    var out, i, lim;
    out = "";
    i = 0; lim = segs.size;
    while({ i < lim }, {
      out = out ++ "/" ++ segs[i];
      i = i + 1;
    });
    out
  };

  setCanonicalPayloads = {
    rootCmd = findChildByName.(tree.root, "commands");
    if(rootCmd.isNil) {
      "⚠️ cannot set payloads: 'commands' missing.".postln;
    }{
      count = 0;
      buildPathsDown = { |node, segs|
        if(node.isLeaf) {
          node.payload = buildPathFromSegments.(segs);
          count = count + 1;
        }{
          node.children.do({ |child|
            var nextSegs;
            nextSegs = segs.copy;
            nextSegs.add(child.name.asString);
            buildPathsDown.(child, nextSegs);
          });
        }
      };
      // seed with immediate children of 'commands'
      rootCmd.children.do({ |child|
        buildPathsDown.(child, [child.name.asString]);
      });
      ("set canonical payloads on " ++ count ++ " leaf/leaves under 'commands'").postln;
    };
  };

  setCanonicalPayloads.();

  // 3) save back to the canonical file
  tree.exportJSONFile(jsonPath);
  ("✅ Updated commands branch in → " ++ jsonPath).postln;

  // 4) sample a few payloads under 'commands' (sanity)
  commandsNode = findChildByName.(tree.root, "commands");
  if(commandsNode.isNil) {
    "⚠️ 'commands' node not found after ensure-path (unexpected).".postln;
  }{
    printSampleLeaves = {
      var visit, payloads;
      payloads = List.new;
      visit = { |n|
        if(n.isLeaf) {
          payloads.add((n.payload ?? n.name).asString);
        }{
          n.children.do(visit);
        }
      };
      visit.(commandsNode);
      ("sample payloads: " ++ showFirstN.(payloads, 8).asString).postln;
    };
    printSampleLeaves.();
  };
}{
  ("❌ Failed to load " ++ jsonPath ++ " (no changes made)").postln;
};

// ── exit banner ──────────────────────────────────────────────────────────────
"Editor_AddCommands_Branch_Canonical: EXIT".postln;
"──────────────────────────────────────────────────────────────────────────────".postln;
)
