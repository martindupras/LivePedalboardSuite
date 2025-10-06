// Bind_CM_to_LPDisplay_Robust.scd
// v0.2.0
// MD 20251003-1412

/* Purpose / Style
- Bind LPDisplayAdapter to a CommandManager:
  • Prefer ~system’s CM if we can find it under common names or by scanning zero-arg methods.
  • Otherwise create a standalone CommandManager.
- Expose deterministic nav helpers bound to explicit strings:
  root → string 6 (frets 1,3,5,7,9), children → string 5, deeper → string 4.
- Style: var-first; tilde vars; lowercase; descriptive names; no server.sync.
*/

(
var findSystemCM, pickOrCreateCM, bindAdapter, tryNav, reportWhich;

// 1) Try to locate a CM on ~system using common selectors or a safe zero-arg scan
findSystemCM = {
    var cmObj, preferred, allNames, hits;
    cmObj = nil;
    if(~system.notNil) {
        preferred = [\commandManager, \cmdManager, \cm, \manager].detect({ arg sel;
            (~system.respondsTo(sel)) and: { ~system.perform(sel).notNil }
        });
        if(preferred.notNil) {
            cmObj = ~system.perform(preferred);
        }{
            // scan only safe zero-arg methods whose names *look* like managers
            allNames = ~system.class.methods.collect(_.name).collect(_.asString);
            hits = allNames.select({ arg n;
                var ns = n.toLower;
                (ns.contains("command") or: { ns.contains("manager") or: { ns == "cm" or: { ns.contains("cmd") } } })
            });
            hits.do({ arg n;
                var candidate;
                candidate = ~system.tryPerform(n.asSymbol);
                if(candidate.notNil and: { candidate.respondsTo(\updateDisplay) and: { candidate.respondsTo(\builder) } }) {
                    cmObj = candidate;
                };
            });
        };
    };
    cmObj
};

// 2) Choose CM: prefer system CM, else create a standalone one
pickOrCreateCM = {
    var cmLocal;
    cmLocal = findSystemCM.();
    cmLocal = (cmLocal.notNil).if({ cmLocal }, { CommandManager.new(nil) });
    ~cm = cmLocal;  // publish for quick access elsewhere
    cmLocal
};

// 3) Bind adapter to the chosen CM (idempotent), and show initial display
bindAdapter = { arg cmLocal;
    var adapterLocal;
    adapterLocal = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(~guiLP) });
    ~lp_adapter = adapterLocal;
    cmLocal.display = adapterLocal;
    cmLocal.updateDisplay;
    adapterLocal
};

// 4) Deterministic navigation (explicit string/fret); always writes Diag feedback
tryNav = { arg cmLocal, stringNum, fretNum;
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

// 5) Report which CM we bound to (system vs standalone)
reportWhich = { arg cmLocal;
    var isSystemCM;
    isSystemCM = (~system.notNil) and: {
        [\commandManager, \cmdManager, \cm, \manager].any({ arg sel;
            (~system.respondsTo(sel)) and: { ~system.perform(sel) === cmLocal }
        })
    };
    (isSystemCM.if({ "Bound to: SYSTEM CommandManager" }, { "Bound to: STANDALONE CommandManager" })).postln;
};

// sequence
~cm = pickOrCreateCM.();
bindAdapter.(~cm);
reportWhich.(~cm);

// public helpers (root-first: 6→5→4)
~nav6 = { arg fret; tryNav.(~cm, 6, fret) };  // root
~nav5 = { arg fret; tryNav.(~cm, 5, fret) };  // depth 1
~nav4 = { arg fret; tryNav.(~cm, 4, fret) };  // depth 2+

"Nav ready. From root use ~nav6.(1|3|5|7|9); then ~nav5.(3|5|7); then ~nav4.(3|5|7).".postln;

// tracked progress
~md_progress = (~md_progress ? List.new).add("Robust bind + nav @ " ++ Date.localtime.stamp);
)