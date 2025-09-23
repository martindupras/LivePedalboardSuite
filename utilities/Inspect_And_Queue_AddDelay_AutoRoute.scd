// Inspect_And_Queue_AddDelay_AutoRoute.scd
// v1.0.0
// MD 2025-09-23 14:10 BST

/* Purpose
   - With no hardware, locate the node named "delay" anywhere in the CommandTree,
     derive the name-route from root, navigate with your builder (by name),
     and queue the SHORT canonical "/add/delay" (Step 2 ONLY; no send).
   - Prints available children at each navigation step for clarity.

   Style
   - var-first in every block; descriptive variable names.
   - AppClock-only for GUI; no server.sync; no SoundIn.
   - Uses only ~system; assumes Start_LivePedalboardSystem.scd (Option B) has run.
*/

(
var environmentReady, commandManager, commandTree, commandTreeBuilder, commandQueue;
var showStatusMessage, printChildrenHere, navigateOneStepByName, navigateSequenceWithDiagnostics;
var findFirstPathByNameDFS, discoveredPathNames, navigationSucceeded;
var longPathString, queueListText, canonicalPathString, displayRef;

// --- environment guards ---
environmentReady = (~system.notNil)
  and: { ~system.commandManager.notNil }
  and: { ~system.commandManager.builder.notNil }
  and: { ~system.commandManager.queue.notNil }
  and: { ~system.commandManager.tree.notNil };

if(environmentReady.not) {
  "⚠️ Bring-up first: evaluate Start_LivePedalboardSystem.scd (Option B).".warn;
  ^nil;
};

// --- shorthands ---
commandManager      = ~system.commandManager;
commandTree         = commandManager.tree;
commandTreeBuilder  = commandManager.builder;
commandQueue        = commandManager.queue;
displayRef          = commandManager.display;

// --- helper: status to GUI / console ---
showStatusMessage = { |messageText|
  AppClock.sched(0.0, {
    var canShow;
    canShow = displayRef.notNil and: { displayRef.respondsTo(\showExpectation) };
    if(canShow) { displayRef.showExpectation(messageText, 0) } { ("[SIM] " ++ messageText).postln };
    nil
  });
};

// --- helper: print current children (name + fret) ---
printChildrenHere = {
  var childrenArray, childLines;
  if(commandTreeBuilder.currentNode.isNil) {
    "[SIM] No current node.".postln; ^nil
  };
  childrenArray = commandTreeBuilder.currentNode.children ? [];
  if(childrenArray.isEmpty) {
    "[SIM] No children at this node.".postln;
  }{
    childLines = childrenArray.collect({ |childNode|
      "  • " ++ childNode.name.asString ++ "  (fret " ++ childNode.fret.asString ++ ")"
    }).join("\n");
    ("[SIM] Available children:\n" ++ childLines).postln;
  };
  ^nil
};

// --- helper: one step by name, with diagnostics ---
navigateOneStepByName = { |childNameToSelect|
  var nextNodeAfterStep;
  nextNodeAfterStep = commandTreeBuilder.navigateByName(nil, childNameToSelect);
  if(nextNodeAfterStep.isNil or: { nextNodeAfterStep.name.asString != childNameToSelect.asString }) {
    ("❌ navigation failed at '" ++ childNameToSelect ++ "'").warn;
    printChildrenHere.();
    ^false;
  };
  ^true;
};

// --- helper: navigate a full sequence of names from root ---
navigateSequenceWithDiagnostics = { |nameSequence|
  var stepSucceeded, currentIndex, sequenceLength, currentName;
  stepSucceeded  = true;
  currentIndex   = 0;
  sequenceLength = nameSequence.size;

  commandTreeBuilder.resetNavigation;

  while({ currentIndex < sequenceLength and: { stepSucceeded } }, {
    currentName = nameSequence[currentIndex];
    ("[SIM] step " ++ (currentIndex+1).asString ++ "/" ++ sequenceLength.asString
      ++ ": selecting '" ++ currentName ++ "'").postln;
    printChildrenHere.();
    stepSucceeded = navigateOneStepByName.(currentName);
    currentIndex  = currentIndex + 1;
  });

  ^stepSucceeded;
};

// --- helper: DFS to find a node by name; returns ['root', ..., name] or nil ---
findFirstPathByNameDFS = { |targetNameString|
  var foundPathNames, traverseDepthFirst;

  foundPathNames = nil;

  traverseDepthFirst = { |nodeRef, pathSoFar|
    var newPath, childIdx, childNode, pathDone;
    if(foundPathNames.notNil) { ^nil }; // already found
    newPath = pathSoFar.add(nodeRef.name.asString);
    if(nodeRef.name.asString == targetNameString.asString) {
      foundPathNames = newPath.deepCopy; // include 'root' up to the target
      ^nil;
    };
    // iterate children
    childIdx = 0;
    while({ childIdx < nodeRef.children.size and: { foundPathNames.isNil } }, {
      childNode = nodeRef.children[childIdx];
      traverseDepthFirst.(childNode, newPath.copy);
      childIdx = childIdx + 1;
    });
    ^nil;
  };

  traverseDepthFirst.(commandTree.root, List.new);
  ^foundPathNames; // may be nil
};

// --- find a path to "delay" and navigate it ---
discoveredPathNames = findFirstPathByNameDFS.("delay");

if(discoveredPathNames.isNil) {
  "❌ Could not find a node named 'delay' in the current CommandTree.".warn;
  "Tip: run TestLogging_CommandTree.scd to print the structure, or tell me the exact branch where 'delay' lives.".postln;
  ^nil;
};

// drop the 'root' element; builder expects only child names from root downward
discoveredPathNames = if(discoveredPathNames.size > 1) {
  discoveredPathNames.copyRange(1, discoveredPathNames.size - 1)
}{
  [] // degenerate (shouldn't happen for a leaf)
};

showStatusMessage.("Simulating Step 2: navigating to " ++ discoveredPathNames.asString);

navigationSucceeded = navigateSequenceWithDiagnostics.(discoveredPathNames);

if(navigationSucceeded.not) {
  "❌ Navigation failed following the discovered path. Check the printed children.".warn;
  ^nil;
};

// post long path (informational)
longPathString = "/" ++ discoveredPathNames.join("/");
("[SIM] long=" ++ longPathString).postln;

// Step 2 requirement: QUEUE the SHORT canonical "/add/delay"
canonicalPathString = "/add/delay";
commandQueue.enqueueCommand(canonicalPathString);

// refresh GUI text fields
queueListText = commandQueue.commandList.collect({ |cmdString| "- " ++ cmdString.asString }).join("\n");
AppClock.sched(0.0, {
  var canUpdate;
  canUpdate = displayRef.notNil and: { displayRef.respondsTo(\updateTextField) };
  if(canUpdate) {
    displayRef.updateTextField(\state, "Mode: queue (simulated)");
    displayRef.updateTextField(\queue, "Current Queue:\n" ++ queueListText);
    displayRef.updateTextField(\lastCommand, "Last Added: " ++ canonicalPathString);
  }{
    ("[SIM] queued:\n" ++ queueListText).postln;
  };
  nil
});

// Optional: if you want to SEND immediately (Step 3), un-comment:
// if(commandManager.queueExportCallback.notNil) {
//   commandManager.queueExportCallback.value(canonicalPathString);
// };
)
