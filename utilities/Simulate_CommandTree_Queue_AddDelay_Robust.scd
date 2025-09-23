// Simulate_CommandTree_Queue_AddDelay_Robust.scd
// v1.0.4
// MD 2025-09-23 14:08 BST

/* Purpose
   Emulate Step 2 without hardware:
   - Try likely routes to "delay", printing children BEFORE and AFTER each step.
   - Queue SHORT canonical "/add/delay" when any route succeeds.
   - Does NOT send; purely queues as per Step 2.

   Style
   - var-first in every block; descriptive var names; AppClock-only UI; no server.sync.
   - Uses only ~system; assumes Start_LivePedalboardSystem.scd (Option B) has run.
*/

(
var environmentReady, commandManager, commandTreeBuilder, commandQueue;
var showStatusMessage, printChildrenOf, navigateOneStepByName, navigateSequenceVerbose;
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

// Pretty-print a node's children (name + fret)
printChildrenOf = { |labelText|
  var childrenArray, childLines;
  if(commandTreeBuilder.currentNode.isNil) {
    ("[SIM] " ++ labelText ++ ": <no current node>").postln; ^nil
  };
  childrenArray = commandTreeBuilder.currentNode.children ? [];
  if(childrenArray.isEmpty) {
    ("[SIM] " ++ labelText ++ ": <no children>").postln;
  }{
    childLines = childrenArray.collect({ |childNode|
      "  • " ++ childNode.name.asString ++ "  (fret " ++ childNode.fret.asString ++ ")"
    }).join("\n");
    ("[SIM] " ++ labelText ++ ":\n" ++ childLines).postln;
  };
  ^nil;
};

// Navigate one step by name; logs before/after child lists
navigateOneStepByName = { |childNameToSelect, stepIndex, totalSteps|
  var nextNodeAfterStep, header;
  header = "[SIM] step " ++ (stepIndex+1).asString ++ "/" ++ totalSteps.asString
         ++ ": selecting '" ++ childNameToSelect ++ "'";
  header.postln;

  printChildrenOf.("Children BEFORE");

  nextNodeAfterStep = commandTreeBuilder.navigateByName(nil, childNameToSelect);
  if(nextNodeAfterStep.isNil or: { nextNodeAfterStep.name.asString != childNameToSelect.asString }) {
    ("❌ navigation failed at '" ++ childNameToSelect ++ "'").warn;
    ^false;
  };

  printChildrenOf.("Children AFTER");
  ^true;
};

// Navigate full sequence; returns true on success
navigateSequenceVerbose = { |nameSequence|
  var stepSucceeded, currentIndex, sequenceLength, currentName;
  stepSucceeded  = true;
  currentIndex   = 0;
  sequenceLength = nameSequence.size;

  commandTreeBuilder.resetNavigation; // restart from root

  while({ currentIndex < sequenceLength and: { stepSucceeded } }, {
    currentName   = nameSequence[currentIndex];
    stepSucceeded = navigateOneStepByName.(currentName, currentIndex, sequenceLength);
    currentIndex  = currentIndex + 1;
  });

  ^stepSucceeded;
};

// Build long internal path (for logging only)
buildLongPathFromBuilder = {
  var namesFromRoot, filteredNames, rawPathString;
  namesFromRoot  = commandTreeBuilder.currentNode.getPathToRoot;
  filteredNames  = if(namesFromRoot.size > 1) { namesFromRoot.copyRange(1, namesFromRoot.size - 1) } { [] };
  rawPathString  = "/" ++ filteredNames.join("/");
  ^rawPathString;
};

// Map long → short canonical understood by MPB
canonicalizeLongPath = { |rawPathString|
  var pathSegments, firstSegment, secondSegment;
  pathSegments  = rawPathString.asString.split($/).reject({ |s| s.size == 0 });
  if(pathSegments.size == 0) { ^rawPathString.asString };
  firstSegment = pathSegments[0].asString;

  if(firstSegment == "switch") { ^"/switch" };

  if(firstSegment == "chain") {
    if(pathSegments.size >= 3) {
      secondSegment = pathSegments[1].asString;

      if(secondSegment == "add" and: { pathSegments[2].asString == "audio" }) {
        ^("/add/" ++ pathSegments.last.asString);
      };
      if(secondSegment == "setsource"
        and: { pathSegments.size >= 5 }
        and: { pathSegments[2].asString == "audio" }
        and: { pathSegments[3].asString == "source" }) {
        ^("/setSource/" ++ pathSegments.last.asString);
      };
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

commandQueue.clearQueue;

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
    routeSucceeded = navigateSequenceVerbose.(nameSequence);
    if(routeSucceeded) { chosenSequence = nameSequence.deepCopy };
  };
});

if(routeSucceeded) {
  longPathString      = buildLongPathFromBuilder.();
  canonicalPathString = canonicalizeLongPath.(longPathString);

  // For Step 2, queue the short canonical form explicitly:
  canonicalPathString = "/add/" ++ targetEffectName;

  ("[SIM] navigation OK via: " ++ chosenSequence.asString).postln;
  ("[SIM] long="  ++ longPathString).postln;
  ("[SIM] short=" ++ canonicalPathString).postln;

  enqueueCanonicalPath.(canonicalPathString);

  // Optional: send now (Step 3). Un-comment if desired:
  // if(commandManager.queueExportCallback.notNil) { commandManager.queueExportCallback.value(canonicalPathString) };

}{
  showStatusMessage.("Navigation failed for all candidates. Paste the BEFORE/AFTER children for the failing step and we'll adapt.");
};
)
