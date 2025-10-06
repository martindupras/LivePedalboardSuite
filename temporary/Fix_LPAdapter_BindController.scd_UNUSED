// Fix_LPAdapter_BindController.scd
// v0.1.0
// MD 20251004-1820

/* Purpose
- If LPDisplayAdapter.controller is a Symbol (e.g., \guiLP), bind the actual window (~guiLP).
- Repaint ACTIVE/NEXT once.
*/

(
var cm, disp, ctrl;
cm = ~system.tryPerform(\commandManager);
if(cm.isNil) { "No ~system.commandManager. Run Start_LivePedalboardSuite_BringUp.scd first.".warn; ^nil };

disp = cm.tryPerform(\display);
if(disp.isNil) { "No CommandManager.display. Did autoBindLPDisplayIfPresent run?".warn; ^nil };

ctrl = disp.tryPerform(\controller);

// If controller is a Symbol, fix it
if(ctrl.isKindOf(Symbol)) {
    if(thisProcess.nowExecutingPath.notNil) { }; // no-op; placeholder
    if(thisProcess.interpreter.isKindOf(Object)) { }; // keep env stable

    if(\guiLP.asSymbol.notNil and: { ~guiLP.notNil }) {
        if(disp.respondsTo(\setController)) {
            disp.setController(~guiLP);
            "LPDisplayAdapter controller set to ~guiLP.".postln;
        }{
            "LPDisplayAdapter.setController not found. Recompile after adding LPDisplayAdapter_SetController.sc".warn;
        };
    }{
        "~guiLP is nil; open LPDisplay first.".warn;
    };
};

// Repaint ACTIVE/NEXT once (defaults to A if unset)
disp.tryPerform(\setActiveChainVisual, (~md_currentChain ? \A));
"Fix_LPAdapter_BindController done.".postln;
)