// SimNav_Bridge_ApplyLeafPayload_FIX.scd
// v0.1.2
// MD 2025-09-23 10:45 BST
/* Purpose
 - Make ~nav_handleFret update MagicDisplayGUI choices and apply leaf payloads.
 - Reuse the CommandManager's builder so CommandManager.updateDisplay works.
 - Show canonical path in the GUI before applying via the adapter.
Style
 - var-first; lowercase method names; AppClock-only UI; no server.sync.
*/

(
var haveSystem, manager, builderRef, displayRef, applyPath, choiceLinesFor, setChoicesInGui, showInGui;

// Preconditions (reuse what LivePedalboardSystem created)
haveSystem = ~system.notNil;
if(haveSystem.not) {
    "⚠️ Bring-up first: Start_LivePedalboardSystem.scd (Option B)".warn; ^nil;
};
manager    = ~system.commandManager;
builderRef = manager.builder; // use the manager’s builder so updateDisplay works
displayRef = ~system.statusDisplay;

// Apply a canonical path using your adapter signature (path, mpb, gui)
applyPath = { |canonical|
    var mpb = ~system.pedalboard;
    if(mpb.isNil) { "[BRIDGE] no ~system.pedalboard (bring-up needed)".postln; ^nil };
    ~ct_applyOSCPathToMPB.(canonical, mpb, displayRef);
};

// Build "fret X → Name" lines for the GUI’s Choices panel
choiceLinesFor = { |node|
    var lines;
    lines = List.new;
    if(node.notNil and: { node.children.notEmpty }) {
        node.children.do { |ch|
            lines.add("fret " ++ ch.fret.asString ++ " → " ++ ch.name.asString);
        };
    };
    lines
};

// Push choices text into MagicDisplayGUI (uses your setOperations extension)
setChoicesInGui = { |node|
    var lines = choiceLinesFor.(node);
    if(displayRef.notNil and: { displayRef.respondsTo(\setOperations) }) {
        displayRef.setOperations(lines.asArray);
    };
};

// Show a one-liner in the GUI’s expectation area
showInGui = { |text|
    if(displayRef.notNil and: { displayRef.respondsTo(\showExpectation) }) {
        displayRef.showExpectation(text, 0);
    };
};

// Public API: reset + handleFret using the manager’s builder
~nav_reset = {
    builderRef.resetNavigation;
    manager.updateDisplay; // refresh GUI choices at root
    "[BRIDGE] nav reset".postln;
};

~nav_handleFret = { |stringNum, fretNum|
    // navigate
    builderRef.navigateByFret(stringNum, fretNum);
    // reflect state in GUI immediately
    manager.updateDisplay; // will call setOperations under the hood

    // Leaf? -> apply payload; otherwise just keep showing choices
    if(builderRef.currentNode.notNil and: { builderRef.currentNode.isLeaf }) {
        var payloadString = builderRef.getCurrentPayload.asString; // canonical "/verb/arg..."
        showInGui.("Apply → " ++ payloadString);
        applyPath.(payloadString);
        ~nav_reset.();
    };
};

"[BRIDGE] SimNav patch ready — use ~nav_handleFret.(string,fret); ~nav_reset.()".postln;

// Initial GUI refresh
manager.updateDisplay;
)
