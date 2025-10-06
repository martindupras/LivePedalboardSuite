// Wire_SystemCM_to_LPDisplay_Min.scd
// v0.1.2
// MD 20251003-1455

/* Purpose / Style
- Prefer SYSTEM CommandManager (if LivePedalboardSystem class is available), else use STANDALONE CM.
- Bind LPDisplayAdapter (~lp_adapter) to whichever CM we use and refresh panes once.
- Deterministic navigation helpers:
    root   → string 6 (frets 1,3,5,7,9)
    depth1 → string 5 (frets 3,5,7,...)
    depth2+→ string 4 (frets 3,5,7,...)
- Style: tilde vars; var-first; lowercase; descriptive names; no server.sync.
*/

(
var lpsClass, systemCm, selectors, sel, cmLocal, adapterLocal, bind, tryNav, report;

// prefer system CM if class exists + selector resolves; else fallback
lpsClass = \LivePedalboardSystem.asClass;
systemCm = nil;

if(lpsClass.notNil) {
    if(~system.isNil) { ~system = lpsClass.new(nil) };  // no extra GUI
    selectors = [\commandManager, \cmdManager, \cm, \manager];
    sel = selectors.detect({ arg s; ~system.respondsTo(s) and: { ~system.perform(s).notNil } });
    (sel.notNil).if({ systemCm = ~system.perform(sel) });
};

cmLocal = (systemCm.notNil).if({ systemCm }, { CommandManager.new(nil) });
~cm = cmLocal;

// bind adapter and refresh
bind = {
    adapterLocal = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(~guiLP) });
    ~lp_adapter = adapterLocal;
    cmLocal.display = adapterLocal;
    cmLocal.updateDisplay;
    nil
};
bind.();

// deterministic string navigation; always echo a Diag line
tryNav = { arg stringNum, fretNum;
    var ok;
    ok = cmLocal.builder.tryPerform(\navigateByFret, stringNum, fretNum);
    (ok == false or: { ok.isNil }).if({ ok = cmLocal.builder.tryPerform(\navigateByFret, fretNum) });
    cmLocal.updateDisplay;
    (~guiLP.notNil).if({
        ~guiLP.sendPaneText(\diag, "Tried: string " ++ stringNum ++ ", fret " ++ fretNum ++ " | result: " ++ ok.asString);
    });
    ok
};

// publish helpers
~nav6 = { arg fret; tryNav.(6, fret) };  // root
~nav5 = { arg fret; tryNav.(5, fret) };  // depth 1
~nav4 = { arg fret; tryNav.(4, fret) };  // depth 2+

// report binding
report = {
    var systemBound;
    systemBound = (systemCm.notNil) and: {
        [\commandManager, \cmdManager, \cm, \manager].any({ arg s; ~system.respondsTo(s) and: { ~system.perform(s) === cmLocal } })
    };
    (systemBound.if({ "Bound to: SYSTEM CommandManager" }, { "Bound to: STANDALONE CommandManager" })).postln;
};
report.();

"Nav ready. From root use ~nav6.(1|3|5|7|9); then ~nav5.(3|5|7); then ~nav4.(3|5|7).".postln;
)