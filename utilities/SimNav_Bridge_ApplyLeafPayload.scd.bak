// SimNav_Bridge_ApplyLeafPayload.scd
// v0.1.1
// MD 20250923-1021

(
/*
Purpose
- Bridge the MIDI simulation to CommandTree navigation; on leaf under "commands",
  apply its canonical payload ("/add/delay", "/switch", etc.) via the adapter to MagicPedalboardNew.

Style
- var-first; lowercase methods; no server.sync; .scd-safe (no caret returns).
*/

var jsonPath, tree, ok, proceed, builder;
var requireOk, ensureAdapter, applyPath;

// ---- small utilities --------------------------------------------------------
requireOk = { |cond, msg|
  if(cond.not) { msg.postln };
  cond
};

ensureAdapter = {
  var candidates, i, p;
  if(~ct_applyOSCPathToMPB.isNil) {
    candidates = List[
      Platform.userExtensionDir ++ "/LivePedalboardSuite/Magicpedalboard/adapter_CommandTree_to_MagicPedalboard.scd",
      Platform.userExtensionDir ++ "/LivePedalboardSuite/Magicpedalboard/adapter_commandtree_to_magicpedalboard.scd"
    ];
    i = 0;
    while({ i < candidates.size }, {
      p = candidates[i].standardizePath;
      if(File.exists(p)) { p.load };
      i = i + 1;
    });
  };
  ~ct_applyOSCPathToMPB.notNil
};

applyPath = { |p|
  var pedalboardRef, guiRef;
  pedalboardRef = nil; guiRef = nil;
  if(~system.notNil) {
    pedalboardRef = ~system.pedalboard;
    guiRef = ~system.statusDisplay;
  };
  if(pedalboardRef.isNil) {
    "[BRIDGE] no ~system.pedalboard (bring-up needed)".postln;
  }{
    ("[BRIDGE] apply → " ++ p).postln;
    ~ct_applyOSCPathToMPB.(p, pedalboardRef, guiRef);
  };
};

// ---- 1) preconditions: bring-up + adapter ----------------------------------
proceed = true;
proceed = proceed and: { requireOk.(~system.notNil, "⚠️ Bring-up first: Start_LivePedalboardSystem.scd (Option B)") };
proceed = proceed and: { requireOk.(ensureAdapter.(), "⚠️ Adapter missing; evaluate adapter_* file") };

// ---- 2) load the same JSON that LivePedalboardSystem uses -------------------
if(proceed) {
  jsonPath = Platform.userExtensionDir
    ++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";
  tree = MDCommandTree.new("root");
  ok = tree.importJSONFile(jsonPath);
  ("[BRIDGE] import ok → " ++ ok).postln;
  proceed = ok;
};

// ---- 3) create builder and expose simple API --------------------------------
if(proceed) {
  builder = MDCommandBuilder.new(tree);

  ~nav_reset = {
    builder.reset;
    "[BRIDGE] nav reset".postln;
  };

  ~nav_handleFret = { |stringNum, fretNum|
    var node, payloadString;
    builder.navigateToChild(stringNum, fretNum);
    node = builder.currentNode;

    if(node.notNil and: { node.isLeaf }) {
      // 'commands' leaves already carry canonical string payloads (set by your editor)
      payloadString = builder.getCurrentCommand.asString;
      applyPath.(payloadString);
      ~nav_reset.();
    }{
      // optional: list children at this level to see available frets
      builder.listChildren;
    };
  };

  "[BRIDGE] ready — call ~nav_handleFret.(string, fret); use ~nav_reset.() to restart.".postln;
};
)
