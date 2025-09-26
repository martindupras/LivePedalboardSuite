// Diag_0G_CreateGuiAndBind.scd
// v0.1.0
// MD 2025-09-26 17:05 BST

/* Purpose / Style
   Purpose: Ensure a single MagicDisplayGUI window exists, bind it to CommandManager.display,
            and return → a Window (final expression).
   Style:   var-first; descriptive lowercase variable names (≥3 chars); no server.sync; AppClock implied.
*/

(
var systemRef, guiWindow, cmdMgr;

systemRef = ~system;
if(systemRef.isNil) {
    // If system doesn’t exist yet, construct with default path resolver.
    ~system = LivePedalboardSystem.new(nil);         // uses your resolveTreePath  (known-good)
    ~system.bringUpAll;
};

// Bring up (or refresh) the single GUI window
~system.closeExistingMagicDisplayWindows;
guiWindow = ~system.bringUpMagicDisplayGUI;          // sets statusDisplay inside LivePedalboardSystem

// Bind CommandManager.display to the GUI object if needed
cmdMgr = ~system.commandManager;
if(cmdMgr.notNil and: { cmdMgr.display.isNil } and: { ~system.statusDisplay.notNil }) {
    cmdMgr.display = ~system.statusDisplay;
    "MD0G: bound CommandManager.display to statusDisplay".postln;
};

// Final expression → a Window (per your rule)
guiWindow
)
