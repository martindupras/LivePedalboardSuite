// Inspect_CommandTree_Under_Chain.scd
// v0.1.0
// MD 20250923--1255

/* Purpose
   Print child names (with frets) under "chain"; also prints under "add" if present.
   Helps confirm the live tree route to "delay".
   Style
   - var-first; descriptive variable names; no server.sync.
*/

(
var environmentReady, commandManager, commandTree, chainNode, addNode;
var listChildren, findChildByName;

environmentReady = (~system.notNil) and: { ~system.commandManager.notNil };
if(environmentReady.not) { "⚠️ Bring-up first (Start_LivePedalboardSystem.scd, Option B).".warn; ^nil };

commandManager = ~system.commandManager;
commandTree    = commandManager.tree;

listChildren = { |nodeRef, labelText|
  var childrenArray, childLines;
  if(nodeRef.isNil) { ("[INSPECT] " ++ labelText ++ ": <nil>").postln; ^nil };
  childrenArray = nodeRef.children ? [];
  if(childrenArray.isEmpty) {
    ("[INSPECT] " ++ labelText ++ ": <no children>").postln;
  }{
    childLines = childrenArray.collect({ |childNode|
      "  • " ++ childNode.name.asString ++ "  (fret " ++ childNode.fret.asString ++ ")"
    }).join("\n");
    ("[INSPECT] " ++ labelText ++ ":\n" ++ childLines).postln;
  };
  ^nil
};

findChildByName = { |parentNode, childNameString|
  if(parentNode.isNil) { ^nil };
  ^parentNode.getChildByName(childNameString.asString);
};

// 1) under "chain"
chainNode = commandTree.root.getChildByName("chain");
listChildren.(chainNode, "Children under [chain]");

// 2) under "chain → add" (if present)
addNode = findChildByName.(chainNode, "add");
if(addNode.notNil) { listChildren.(addNode, "Children under [chain → add]") };
)
