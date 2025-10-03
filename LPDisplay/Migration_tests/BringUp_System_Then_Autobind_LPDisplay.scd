// BringUp_System_Then_Autobind_LPDisplay.scd
// v0.1.0
// MD 20251003-1559

/* Purpose / Style
- Ensure ~system exists (if LivePedalboardSystem is compiled), resolve its CommandManager,
  bind LPDisplayAdapter, and refresh LPDisplay panes once.
- Non-destructive to audio: does not clear the server tree.
- Style: tilde vars; var-first; lowercase; descriptive names; no server.sync.
*/

(
var lpsClass, ensureSystem, resolveCm, bindAdapter, reportBind, cmLocal, pathNote;

// 0) get the class if compiled
lpsClass = \LivePedalboardSystem.asClass;

// 1) create ~system if class exists and ~system is nil (non-destructive)
ensureSystem = {
    if(lpsClass.notNil and: { ~system.isNil }) {
        ~system = lpsClass.new(nil);  // uses class defaults; opens no extra GUI here
        "System created (LivePedalboardSystem).".postln;
        (~md_log.notNil).if({ ~md_log.("System created by BringUp_System_Then_Autobind") });
    };
    nil
};

// 2) resolve CommandManager from ~system
resolveCm = {
    var selectors, pb, pbSelectors, via;
    cmLocal = nil;
    pathNote = "n/a";

    if(~system.notNil) {
        // preferred: accessor you installed today (plus aliases)
        selectors = [\commandManager, \cmdManager, \cm, \manager];
        selectors.do({ arg sel;
            var candidate;
            if(cmLocal.isNil and: { ~system.respondsTo(sel) }) {
                candidate = ~system.perform(sel);
                if(candidate.notNil and: { candidate.respondsTo(\updateDisplay) and: { candidate.respondsTo(\builder) } }) {
                    cmLocal = candidate; pathNote = "~system." ++ sel.asString;
                };
            };
        });

        // fallback: look under pedalboard.* using same selector list
        if(cmLocal.isNil) {
            pb = ~system.tryPerform(\pedalboard);
            if(pb.notNil) {
                pbSelectors = [\commandManager, \cmdManager, \cm, \manager];
                pbSelectors.do({ arg sel;
                    var candidate;
                    if(cmLocal.isNil and: { pb.respondsTo(sel) }) {
                        candidate = pb.perform(sel);
                        if(candidate.notNil and: { candidate.respondsTo(\updateDisplay) and: { candidate.respondsTo(\builder) } }) {
                            cmLocal = candidate; pathNote = "~system.pedalboard." ++ sel.asString;
                        };
                    };
                });
            };
        };
    };
    cmLocal
};

// 3) bind adapter (idempotent) and update panes
bindAdapter = {
    var adapterLocal;
    if(cmLocal.notNil) {
        adapterLocal = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(~guiLP) });
        ~lp_adapter = adapterLocal;
        cmLocal.display = adapterLocal;
        cmLocal.updateDisplay;
        "Adapter bound to SYSTEM CommandManager.".postln;
        (~md_log.notNil).if({ ~md_log.("Auto-bind OK via " ++ pathNote) });
    }{
        (~system.isNil).if({
            "System class missing or ~system not created; staying in STANDALONE mode.".postln;
        },{
            "Could not resolve a system CommandManager; staying in STANDALONE mode.".postln;
        });
    };
    nil
};

// 4) compact report
reportBind = {
    "system class: ".post; (lpsClass.notNil.if({ lpsClass }, { "nil" })).postln;
    "~system present: ".post; (~system.notNil).postln;
    "CM path: ".post; pathNote.postln;
    "display bound: ".post;
    (cmLocal.notNil and: { cmLocal.display.notNil } and: { cmLocal.display.respondsTo(\showExpectation) }).postln;
};

// sequence
ensureSystem.();
resolveCm.();
bindAdapter.();
reportBind.();
)