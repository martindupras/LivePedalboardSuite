// Diag_1_CheckDisplayBinding.scd
// v0.1.0
// MD 2025-09-26 16:55 BST
/* Purpose / Style
   Purpose: Check that CommandManager.display points to the current MagicDisplayGUI object.
            If not, bind it safely (no GUI calls are made here).
   Style:   var-first; descriptive lowercase variable names (>=3 chars); no server.sync.
*/

(
var systemRef, cmdMgr, guiRef, displayBefore, didBind;

systemRef = ~system;
if(systemRef.isNil) { "⚠️ ~system is nil; run your bring-up first.".warn; ^nil };

cmdMgr = systemRef.commandManager;
guiRef = systemRef.statusDisplay;

displayBefore = if(cmdMgr.notNil) { cmdMgr.display } { nil };
"MDSTEP1: before → display.isNil=%  gui.isNil=%".format(displayBefore.isNil, guiRef.isNil).postln;

// Bind only if we have both objects and display is nil
didBind = false;
if(cmdMgr.notNil and: { guiRef.notNil } and: { displayBefore.isNil }) {
    cmdMgr.display = guiRef;
    didBind = true;
    "MDSTEP1: bound CommandManager.display to system.statusDisplay".postln;
};

"MDSTEP1: after  → display.isNil=%  didBind=%".format(cmdMgr.display.isNil, didBind).postln;
nil
)
