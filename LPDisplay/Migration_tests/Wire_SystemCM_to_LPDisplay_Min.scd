// Wire_SystemCM_to_LPDisplay_Min.scd
// v0.1.0
// MD 20251003-1440

/* Purpose / Style
- Prefer the REAL system CommandManager (if LivePedalboardSystem is available); else fallback to a standalone CM.
- Bind LPDisplayAdapter to whichever CM we use.
- Provide deterministic navigation helpers targeting explicit strings:
    root   → string 6 (frets 1,3,5,7,9)
    depth1 → string 5 (frets 3,5,7,...)
    depth2+→ string 4 (frets 3,5,7,...)
- Style: var-first; tilde vars; lowercase; descriptive names; no server.sync.
*/

(
var lpsClass, systemCm, preferredSelector, candidateSelectors, cmLocal, adapterLocal, bindAdapter, tryNav, reportBinding;

// 0) Try to get LivePedalboardSystem class safely (no crash if missing)
lpsClass = \LivePedalboardSystem.asClass;

// 1) Prefer the real system CM if possible
systemCm = nil;
if(lpsClass.notNil) {
    if(~system.isNil) {
        ~system = lpsClass.new(nil);  // uses your class defaults; doesn't open extra GUI
    };
    candidateSelectors = [\commandManager, \cmdManager, \cm, \manager];
    preferredSelector = candidateSelectors.detect({ arg sel;
        (~system.respondsTo(sel)) and: { ~system.perform(sel).notNil }
    });
    if(preferredSelector.notNil) {
        systemCm = ~system.perform(preferredSelector);
    };
};

// 2) Choose a CM: system CM if found, else a standalone CM
cmLocal = (systemCm.notNil).if({ systemCm }, { CommandManager.new(nil) });
~cm = cmLocal;

// 3) Bind adapter idempotently and refresh panes
bindAdapter = {
    adapterLocal = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(~guiLP) });
    ~lp_adapter = adapterLocal;
    cmLocal.display = adapterLocal;
    cmLocal.updateDisplay;  // legacy selectors -> adapter -> LPDisplay panes
    true
};
bindAdapter.();

// 4) Deterministic navigation: always post a Diag line so you see immediate feedback
tryNav = { arg stringNum, fretNum;
    var ok;
    ok = cmLocal.builder.tryPerform(\navigateByFret, stringNum, fretNum);
    (ok == false or: { ok.isNil }).if({
        ok = cmLocal.builder.tryPerform(\navigateByFret, fretNum);
    });
    cmLocal.updateDisplay;
    (~guiLP.notNil).if({
        ~guiLP.sendPaneText(\diag, "Tried: string " ++ stringNum ++ ", fret " ++ fretNum ++ " | result: " ++ ok.asString);
    });
    ok
};

// 5) Public helpers (root-first: 6 → 5 → 4)
~nav6 = { arg fret; tryNav.(6, fret) };  // use at root (frets 1,3,5,7,9)
~nav5 = { arg fret; tryNav.(5, fret) };  // children
~nav4 = { arg fret; tryNav.(4, fret) };  // grandchildren+

// 6) Report what we bound to
reportBinding = {
    var boundToSystem;
    boundToSystem = (systemCm.notNil) and: {
        [\commandManager, \cmdManager, \cm, \manager].any({ arg sel;
            (~system.respondsTo(sel)) and: { ~system.perform(sel) === cmLocal }
        })
    };
    (boundToSystem.if({ "Bound to: SYSTEM CommandManager" }, { "Bound to: STANDALONE CommandManager" })).postln;
};
reportBinding.();

// tip text
"Nav ready. From root use ~nav6.(1|3|5|7|9); then ~nav5.(3|5|7); then ~nav4.(3|5|7).".postln;

// progress (in-memory)
~md_progress = (~md_progress ? List.new).add("Wire_SystemCM_to_LPDisplay_Min @ " ++ Date.localtime.stamp);
)