// LPDisplay_Nav_RootFirst.scd
// v0.1.0
// MD 20251003-1408

/* Purpose / Style
- Deterministic navigation helpers that target a specific string at each step:
  root:   string 6  (frets 1,3,5,7,9)
  depth1: string 5  (frets 3,5,7,...)
  depth2+: string 4 (frets 3,5,7,...)
- Rebind adapter safely if needed, then expose ~nav6, ~nav5, ~nav4.
- Style: tilde vars; var-first; lowercase; descriptive names; no server.sync.
*/

(
var cmLocal, adapterLocal, bindAdapterIfNeeded, forceDiag, tryNav;

// 0) choose a CommandManager source: prefer real system, else fallback standalone
cmLocal = (~cm.notNil).if({
    ~cm
}, {
    (~system.notNil).if({
        var candidates, chosen;
        candidates = [\commandManager, \cmdManager, \cm, \manager];
        chosen = candidates.detect({ arg sel;
            (~system.respondsTo(sel)) and: { ~system.perform(sel).notNil }
        });
        (chosen.notNil).if({ ~system.perform(chosen) }, { CommandManager.new(nil) })
    }, {
        CommandManager.new(nil)
    })
});
~cm = cmLocal;

// 1) bind LPDisplayAdapter to cm.display (idempotent)
bindAdapterIfNeeded = {
    adapterLocal = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(~guiLP) });
    ~lp_adapter = adapterLocal;
    ~cm.display = adapterLocal;
    true
};

forceDiag = { arg text;
    (~guiLP.notNil).if({ ~guiLP.sendPaneText(\diag, text.asString) });
};

tryNav = { arg stringNum, fretNum;
    var ok, beforeText, afterText;
    // attempt preferred signature: navigateByFret(string, fret)
    ok = ~cm.builder.tryPerform(\navigateByFret, stringNum, fretNum);
    // fallback signature used in some branches: navigateByFret(fret)
    (ok == false or: { ok.isNil }).if({
        ok = ~cm.builder.tryPerform(\navigateByFret, fretNum);
    });
    // update the panes whatever happened
    beforeText = "Tried: string " ++ stringNum ++ ", fret " ++ fretNum;
    ~cm.updateDisplay;
    afterText  = " | result: " ++ (ok.asString);
    forceDiag.(beforeText ++ afterText);
    ok
};

// rebind now (safe if already bound)
bindAdapterIfNeeded.();

// expose explicit string helpers
~nav6 = { arg fret; tryNav.(6, fret) };  // use at root: frets 1,3,5,7,9
~nav5 = { arg fret; tryNav.(5, fret) };  // use at depth 1: frets 3,5,7,...
~nav4 = { arg fret; tryNav.(4, fret) };  // use at depth 2+: frets 3,5,7,...

// tip text
"Root-first nav ready. From root use ~nav6.(1|3|5|7|9); then ~nav5.(3|5|7); then ~nav4.(3|5|7).".postln;

// progress (in-memory only)
~md_progress = (~md_progress ? List.new).add("Sprint4.1: root-first nav helpers @ " ++ Date.localtime.stamp);
)
