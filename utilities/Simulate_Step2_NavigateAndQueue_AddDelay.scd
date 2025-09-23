// Simulate_Step2_NavigateAndQueue_AddDelay.scd
// v1.0.0
// MD 20250923-1258

/* Purpose
   Step 2 without hardware:
   - Navigate CommandTree to reach "delay" via real structure:
       (a) chain → add → delay        (preferred if present)
       (b) chain → add → timebased → delay
   - Print children BEFORE and AFTER each selection for visibility.
   - Queue SHORT canonical "/add/delay" (no send; Step 2 only).

   Style
   - var-first in every block or method.
   - descriptive variable names (no segs/eff/arg/pb).
   - AppClock-only for GUI; no server.sync; no SoundIn.
   - Uses only ~system; assumes Start_LivePedalboardSystem.scd (Option B) has run.
*/

(
var environmentReady, commandManager, commandTreeBuilder, commandQueue, displayRef;
var showStatusMessage, printChildrenOfCurrentNode, navigateOneStepByName, navigateSequenceVerbose;
var buildLongPathFromBuilder, canonicalizeLongPath, enqueueCanonicalPath;
var preferredSequences, selectedSequence, routeSucceeded;
var longPathString, canonicalFromPathString, canonicalToQueueString;

// --- guards & shorthands ----------------------------------------------------
environmentReady = (~system.notNil)
  and: { ~system.commandManager.notNil }
  and: { ~system.commandManager.builder.notNil }
  and: { ~system.commandManager.queue.notNil };

if(environmentReady.not) {
  "⚠️ Bring-up first (Start_LivePedalboardSystem.scd, Option B).".warn;
  ^nil;
};

commandManager      = ~system.commandManager;
commandTreeBuilder  = commandManager.builder;
commandQueue        = commandManager.queue;
displayRef          = commandManager.display;

// --- helpers ----------------------------------------------------------------
showStatusMessage = { |messageText|
  var canShow;
  AppClock.sched(0.0, {
    canShow = displayRef.notNil and: { displayRef.respondsTo(\showExpectation) };
    if(canShow) { displayRef.showExpectation(messageText, 0) } { ("[SIM] " ++ messageText).postln };
    nil
  });
};

printChildrenOfCurrentNode = {
  var childrenArray, childLines;
  if(commandTreeBuilder.currentNode.isNil) { "[SIM] <no current node>".postln; ^nil };
  childrenArray = commandTreeBuilder.currentNode.children ? [];
  if(childrenArray.isEmpty) {
    "[SIM] <no children>".postln;
  }{
    childLines = childrenArray.collect({ |childNode|
      var lineText;
      lineText = "  • " ++ childNode.name.asString ++ "  (fret " ++ childNode.fret.asString ++ ")";
      lineText
    }).join("\n");
    ("[SIM] Children:\n" ++ childLines).postln;
  };
  ^nil;
};

navigateOneStepByName = { |childNameToSelect, stepIndexInteger, totalStepsInteger|
  var nextNodeAfterStep, headerText, stepOk;
  var canPrint;
  headerText = "[SIM] step " ++ (stepIndexInteger+1).asString ++ "/" ++ totalStepsInteger.asString
             ++ ": selecting '" ++ childNameToSelect ++ "'";
  headerText.postln;

  "  BEFORE".postln;
  printChildrenOfCurrentNode.();

  nextNodeAfterStep = commandTreeBuilder.navigateByName(nil, childNameToSelect);
  stepOk = (nextNodeAfterStep.notNil) and: { nextNodeAfterStep.name.asString == childNameToSelect.asString };
  if(stepOk.not) {
    ("❌ navigation failed at '" ++ childNameToSelect ++ "'").warn;
    ^false;
  };

  "  AFTER".postln;
  printChildrenOfCurrentNode.();
  ^true;
};

navigateSequenceVerbose = { |nameSequenceArray|
  var stepSucceeded, currentIndexInteger, totalStepsInteger, currentNameString;
  stepSucceeded       = true;
  currentIndexInteger = 0;
  totalStepsInteger   = nameSequenceArray.size;

  commandTreeBuilder.resetNavigation;

  while({ currentIndexInteger < totalStepsInteger and: { stepSucceeded } }, {
    currentNameString  = nameSequenceArray[currentIndexInteger];
    stepSucceeded      = navigateOneStepByName.(currentNameString, currentIndexInteger, totalStepsInteger);
    currentIndexInteger = currentIndexInteger + 1;
  });

  ^stepSucceeded;
};

buildLongPathFromBuilder = {
  var namesFromRootArray, filteredNamesArray, rawPathStringLocal;
  namesFromRootArray  = commandTreeBuilder.currentNode.getPathToRoot; // ["root", ...]
  filteredNamesArray  = if(namesFromRootArray.size > 1) { namesFromRootArray.copyRange(1, namesFromRootArray.size - 1) } { [] };
  rawPathStringLocal  = "/" ++ filteredNamesArray.join("/");
  ^rawPathStringLocal;
};

canonicalizeLongPath = { |rawPathString|
  var pathSegmentsArray, firstSegmentString, secondSegmentString;
  pathSegmentsArray   = rawPathString.asString.split($/).reject({ |s| s.size == 0 });
  if(pathSegmentsArray.size == 0) { ^rawPathString.asString };
  firstSegmentString  = pathSegmentsArray[0].asString;

  if(firstSegmentString == "switch") { ^"/switch" };

  if(firstSegmentString == "chain") {
    if(pathSegmentsArray.size >= 3) {
      secondSegmentString = pathSegmentsArray[1].asString;

      // /chain/add/audio/.../<effect> → /add/<effect>
      if(secondSegmentString == "add" and: { pathSegmentsArray[2].asString == "audio" }) {
        ^("/add/" ++ pathSegmentsArray.last.asString);
      };

      // /chain/setsource/audio/source/<src> → /setSource/<src>
      if(secondSegmentString == "setsource"
        and: { pathSegmentsArray.size >= 5 }
        and: { pathSegmentsArray[2].asString == "audio" }
        and: { pathSegmentsArray[3].asString == "source" }) {
        ^("/setSource/" ++ pathSegmentsArray.last.asString);
      };
    };
    ^rawPathString.asString;
  };

  if(#["add","remove","clear","bypass","swap","setSource","switch"].includes(firstSegmentString)) {
    ^("/" ++ pathSegmentsArray.join("/"));
  };

  ^rawPathString.asString;
};

enqueueCanonicalPath = { |canonicalPathString|
  var queueListAsTextString, canUpdate;
  commandQueue.enqueueCommand(canonicalPathString);
  queueListAsTextString = commandQueue.commandList.collect({ |cmdString| "- " ++ cmdString.asString }).join("\n");

  AppClock.sched(0.0, {
    canUpdate = displayRef.notNil and: { displayRef.respondsTo(\updateTextField) };
    if(canUpdate) {
      displayRef.updateTextField(\state, "Mode: queue (simulated)");
      displayRef.updateTextField(\queue, "Current Queue:\n" ++ queueListAsTextString);
      displayRef.updateTextField(\lastCommand, "Last Added: " ++ canonicalPathString);
    }{
      ("[SIM] queued:\n" ++ queueListAsTextString).postln;
    };
    nil
  });
};

// --- run (Step 2) -----------------------------------------------------------
commandQueue.clearQueue;

preferredSequences = [
  [ "chain", "add", "delay" ],
  [ "chain", "add", "timebased", "delay" ]
];

showStatusMessage.("Step 2: queue '/add/delay' (navigating real tree; trying preferred routes)");

selectedSequence = nil;
routeSucceeded   = false;

preferredSequences.do({ |nameSequenceArray|
  var attemptOk;
  if(routeSucceeded.not) {
    ("[SIM] trying path: " ++ nameSequenceArray.asString).postln;
    attemptOk = navigateSequenceVerbose.(nameSequenceArray);
    if(attemptOk) { routeSucceeded = true; selectedSequence = nameSequenceArray.deepCopy };
  };
});

if(routeSucceeded) {
  longPathString          = buildLongPathFromBuilder.();
  canonicalFromPathString = canonicalizeLongPath.(longPathString);

  // For Step 2, always queue the SHORT canonical for the effect we want:
  canonicalToQueueString  = "/add/delay";

  ("[SIM] navigation OK via: " ++ selectedSequence.asString).postln;
  ("[SIM] long="  ++ longPathString).postln;
  ("[SIM] short=" ++ canonicalToQueueString
    ++ "  (from path→ " ++ canonicalFromPathString ++ ")").postln;

  enqueueCanonicalPath.(canonicalToQueueString);

  // Optional: send immediately (Step 3). Un-comment if desired:
  // if(commandManager.queueExportCallback.notNil) { commandManager.queueExportCallback.value(canonicalToQueueString) };

}{
  // Could not navigate (e.g., effect nested under other category) → still complete Step 2 by queuing canonical.
  "[SIM] falling back: could not navigate to 'delay'; queuing short canonical anyway".warn;
  canonicalToQueueString = "/add/delay";
  enqueueCanonicalPath.(canonicalToQueueString);
};
)
