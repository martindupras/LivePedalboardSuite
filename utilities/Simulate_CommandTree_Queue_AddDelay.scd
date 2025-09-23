// Simulate_CommandTree_Queue_AddDelay.scd
// v1.0.0
// MD 20250923-12:36

// Simulate_CommandTree_Queue_AddDelay_Robust.scd
// v1.0.3
// MD 2025-09-23 13:55 BST

/* Purpose
   Robustly emulate Step 2 with no hardware:
   - Try likely navigation sequences to reach "delay":
       [ "chain","add","delay" ]  (first choice)
       [ "chain","add","timebased","delay" ]
       [ "audio","timebased","delay" ]
   - Print children (name + fret) at each step for visibility.
   - Enqueue the SHORT canonical "/add/delay" once any route succeeds.
   - Does NOT send; purely queues as per Step 2.

   Style
   - var-first in every block or method.
   - descriptive variable names.
   - AppClock-only for GUI updates; no server.sync; no SoundIn.
   - Uses only ~system; assumes Start_LivePedalboardSystem.scd (Option B) has run.
*/

(
var environmentReady, commandManager, commandTreeBuilder, commandQueue;
var showStatusMessage, printChildrenHere, navigateOneStepByName, navigateSequenceWithDiagnostics;
var candidateSequences, chosenSequence, routeSucceeded;
var targetEffectName, longPathString, canonicalPathString;
var buildLongPathFromBuilder, canonicalizeLongPath, enqueueCanonicalPath;

// --- environment guards ---
environmentReady = (~system.notNil)
  and: { ~system.commandManager.notNil }
  and: { ~system.commandManager.builder.notNil }
  and: { ~system.commandManager.queue.notNil };

if(environmentReady.not) {
  "⚠️ Bring-up first: evaluate Start_LivePedalboardSystem.scd (Option B).".warn;
  ^nil;
};

// --- shorthands ---
commandManager     = ~system.commandManager;
commandTreeBuilder = commandManager.builder;
commandQueue       = commandManager.queue;

// --- helpers ---

showStatusMessage = { |messageText|
  var displayRef;
  displayRef = commandManager.display;
  AppClock.sched(0.0, {
    var canShow;
    canShow = displayRef.notNil and: { displayRef.respondsTo(\showExpectation) };
    if(canShow) { displayRef.showExpectation(messageText, 0) } { ("[SIM] " ++ messageText).postln };
    nil
  });
};

// Pretty-print the current node's children (name + fret)
printChildrenHere = {
  var childrenArray, childLines;
  if(commandTreeBuilder.currentNode.isNil) { "[SIM] No current node.".postln; ^nil };
  childrenArray = commandTreeBuilder.currentNode.children ? [];
  if(childrenArray.isEmpty) {
    "[SIM] No children at this node.".postln;
  }{
    childLines = childrenArray.collect({ |childNode|
      "  • " ++ childNode.name.asString ++ "  (fret " ++ childNode.fret.asString ++ ")"
    }).join("\n");
    ("[SIM] Available children:\n" ++ childLines).postln;
  };
  ^nil;
};

// Navigate a single step by name; returns true/false and prints diagnostics if it fails.
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

// Navigate a full sequence; prints children at each step.
navigateSequenceWithDiagnostics = { |nameSequence|
  var stepSucceeded, currentIndex, sequenceLength, currentName;
  stepSucceeded  = true;
  currentIndex   = 0;
  sequenceLength = nameSequence.size;

  commandTreeBuilder.resetNavigation; // restart from root for each attempt

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

// Build long internal path (for visibility/logging)
buildLongPathFromBuilder = {
  var namesFromRoot, filteredNames, rawPathString;
  namesFromRoot  = commandTreeBuilder.currentNode.getPathToRoot;
  filteredNames  = if(namesFromRoot.size > 1) { namesFromRoot.copyRange(1, namesFromRoot.size - 1) } { [] };
  rawPathString  = "/" ++ filteredNames.join("/");
  ^rawPathString;
};

// Long → short canonical path (same rules you use elsewhere)
canonicalizeLongPath = { |rawPathString|
  var pathSegments, firstSegment, secondSegment;
  pathSegments  = rawPathString.asString.split($/).reject({ |s| s.size == 0 });
  if(pathSegments.size == 0) { ^rawPathString.asString };
  firstSegment = pathSegments[0].asString;

  if(firstSegment == "switch") { ^"/switch" };

  if(firstSegment == "chain") {
    if(pathSegments.size >= 3) {
      secondSegment = pathSegments[1].asString;
      if(secondSegment == "add" and: { pathSegments[2].asString == "audio" }) { ^("/add/" ++ pathSegments.last.asString) };
      if(secondSegment == "setsource"
        and: { pathSegments.size >= 5 }
        and: { pathSegments[2].asString == "audio" }
        and: { pathSegments[3].asString == "source" }) { ^("/setSource/" ++ pathSegments.last.asString) };
    };
    ^rawPathString.asString;
  };

  if(#["add","remove","clear","bypass","swap","setSource","switch"].includes(firstSegment)) {
    ^("/" ++ pathSegments.join("/"));
  };

  ^rawPathString.asString;
};

// Enqueue canonical string and refresh GUI
enqueueCanonicalPath = { |canonicalPathString|
  var queueListAsText, displayRef;
  displayRef = commandManager.display;
  commandQueue.enqueueCommand(canonicalPathString);
  queueListAsText = commandQueue.commandList.collect({ |cmdString| "- " ++ cmdString.asString }).join("\n");

  AppClock.sched(0.0, {
    var canUpdate;
    canUpdate = displayRef.notNil and: { displayRef.respondsTo(\updateTextField) };
    if(canUpdate) {
      displayRef.updateTextField(\state, "Mode: queue (simulated)");
      displayRef.updateTextField(\queue, "Current Queue:\n" ++ queueListAsText);
      displayRef.updateTextField(\lastCommand, "Last Added: " ++ canonicalPathString);
    }{
      ("[SIM] queued:\n" ++ queueListAsText).postln;
    };
    nil
  });
};

// --- simulate Step 2 (robust) ---

commandQueue.clearQueue; // start fresh
targetEffectName  = "delay";
candidateSequences = [
  [ "chain", "add", targetEffectName ],
  [ "chain", "add", "timebased", targetEffectName ],
  [ "audio", "timebased", targetEffectName ]
];

showStatusMessage.("Simulating Step 2: queue '/add/delay' (trying multiple routes)");

chosenSequence = nil;
routeSucceeded = false;

candidateSequences.do({ |nameSequence|
  if(routeSucceeded.not) {
    ("[SIM] trying path: " ++ nameSequence.asString).postln;
    routeSucceeded = navigateSequenceWithDiagnostics.(nameSequence);
    if(routeSucceeded) { chosenSequence = nameSequence.deepCopy };
  };
});

if(routeSucceeded) {
  longPathString      = buildLongPathFromBuilder.();
  canonicalPathString = canonicalizeLongPath.(longPathString);

  // Regardless of route, queue the canonical short for Step 2:
  canonicalPathString = "/add/" ++ targetEffectName;

  ("[SIM] navigation OK via: " ++ chosenSequence.asString).postln;
  ("[SIM] long="  ++ longPathString).postln;
  ("[SIM] short=" ++ canonicalPathString).postln;

  enqueueCanonicalPath.(canonicalPathString);

  // Optional: auto-send immediately (uncomment if you want Step 3 here):
  // if(commandManager.queueExportCallback.notNil) { commandManager.queueExportCallback.value(canonicalPathString) };

}{
  showStatusMessage.("Navigation failed for all candidates. Use the printed child lists to adjust the route.");
};
)

