// LPDisplay_Navigation_Smoke_DepthAware.scd
// v0.2.0
// MD 20251003-1358

/* Purpose / Style
- Depth-aware navigation helpers so a fret press from root uses string 6,
  at depth 1 uses string 5, and deeper uses string 4.
- Works with standalone ~cm (CommandManager) and your LPDisplayAdapter.
- Style: tilde vars; var-first; lowercase; descriptive names; no server.sync.
*/

(
var cmLocal, adapterLocal, showNow, depthOf, targetStringForDepth, tryNavigate, showDiag;

// 1) CommandManager (standalone if ~system not present)
cmLocal = (~cm.notNil).if({ ~cm }, { CommandManager.new(nil) });
~cm = cmLocal;

// 2) Ensure adapter is present and bound to the current LPDisplay controller
adapterLocal = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(~guiLP) });
~lp_adapter = adapterLocal;
cmLocal.display = adapterLocal;

// helper: compute depth from canonical path (root -> 0, first child -> 1, etc.)
depthOf = {
    var canon, parts, depthCount;
    canon = (~cm.respondsTo(\canonicalPathFromBuilder))
        .if({ ~cm.canonicalPathFromBuilder(~cm.builder).asString }, { "root" });

    parts = canon.split($/).reject({ arg s; s.isEmpty });
    depthCount = if(canon == "root" or: { canon == "/" }) { 0 } { parts.size };
    depthCount
};

// helper: choose string index from depth
targetStringForDepth = { arg depthCount;
    if(depthCount <= 0) { 6 } { if(depthCount == 1) { 5 } { 4 } }
};

// try a depth-aware navigate; return true if it appears to succeed
tryNavigate = { arg fret;
    var depthCount, targetString, ok, beforeCanon, afterCanon;
    depthCount = depthOf.();
    targetString = targetStringForDepth.(depthCount);

    beforeCanon = (~cm.respondsTo(\canonicalPathFromBuilder))
        .if({ ~cm.canonicalPathFromBuilder(~cm.builder).asString }, { "n/a" });

    // Preferred form: (string, fret)
    ok = ~cm.builder.tryPerform(\navigateByFret, targetString, fret);

    // Fallback: some older signatures might ignore the string argument
    (ok == false or: { ok.isNil }).if({
        ok = ~cm.builder.tryPerform(\navigateByFret, nil, fret);
    });

    afterCanon = (~cm.respondsTo(\canonicalPathFromBuilder))
        .if({ ~cm.canonicalPathFromBuilder(~cm.builder).asString }, { "n/a" });

    // consider it succeeded if the canonical path changed
    (afterCanon != beforeCanon)
};

// show panes and the canonical "Next:" in Diag
showDiag = {
    var canon;
    canon = (~cm.respondsTo(\canonicalPathFromBuilder))
        .if({ ~cm.canonicalPathFromBuilder(~cm.builder) }, { "n/a" });
    (~guiLP.notNil).if({ ~guiLP.sendPaneText(\diag, "Next: " ++ canon.asString) });
};

showNow = {
    ~cm.updateDisplay;  // legacy selectors -> adapter -> LPDisplay panes
    showDiag.();
};

// PUBLIC one-liners (depth-aware now)
~nav_show  = { showNow.() };
~nav_fret  = { arg fret;
    var ok, depthCountNow, chosenString;

    depthCountNow = depthOf.();
    chosenString  = targetStringForDepth.(depthCountNow);

    ok = tryNavigate.(fret);
    (ok.not).if({
        "No mapping for fret % at depth % (target string %)."
        .format(fret, depthCountNow, chosenString)
        .postln;
    });

    showNow.();
};
~nav_reset = {
    ~cm.builder.tryPerform(\resetNavigation);
    showNow.();
    "🔄 Navigation reset".postln;
};

// small where-am-I helper (optional)
~nav_where = {
    var depthCountNow, chosenString, canon;
    depthCountNow = depthOf.();
    chosenString  = targetStringForDepth.(depthCountNow);
    canon = (~cm.respondsTo(\canonicalPathFromBuilder))
        .if({ ~cm.canonicalPathFromBuilder(~cm.builder) }, { "n/a" });
    ("Depth=" ++ depthCountNow ++ " → string " ++ chosenString ++ " | path=" ++ canon).postln;
};

// initial smoke
"Depth-aware nav ready. From root use ~nav_fret.(1|3|5|7|9); then ~nav_fret.(3|5|7)…; ~nav_where.() shows mapping."
.postln;
~nav_show.();

// progress note (in-memory only)
~md_progress = (~md_progress ? List.new).add("Sprint3: depth-aware nav v0.2.0 @ " ++ Date.localtime.stamp);
)