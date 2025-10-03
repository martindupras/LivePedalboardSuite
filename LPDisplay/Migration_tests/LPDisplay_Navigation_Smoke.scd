// LPDisplay_Navigation_Smoke.scd
// v0.1.1
// MD 20251003-1342

/* Purpose / Style
- Standalone CommandManager → LPDisplay via LPDisplayAdapter.
- Drive real navigation text into LPDisplay (System, Choices, Diag).
- Style: var-first; tilde vars; lowercase; known-good SC; AppClock only in classes.
*/

(
var cmLocal, adapterLocal, showNow;

// 1) CommandManager (standalone); it resolves default tree path inside the class
cmLocal = (~cm.notNil).if({ ~cm }, { CommandManager.new(nil) });
~cm = cmLocal;

// 2) Ensure adapter is present and bound to the current LPDisplay controller
adapterLocal = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(~guiLP) });
~lp_adapter = adapterLocal;
cmLocal.display = adapterLocal;

// 3) Small helper to refresh panes (declaring vars first INSIDE the block too)
showNow = {
    var hasCanon, canonText;

    hasCanon = ~cm.respondsTo(\canonicalPathFromBuilder) and: { ~cm.builder.notNil };
    canonText = if(hasCanon) { ~cm.canonicalPathFromBuilder(~cm.builder) } { "n/a" };

    // This triggers CommandManager → (legacy selectors) → adapter → LPDisplay panes
    ~cm.updateDisplay;

    // Show canonical "Next:" in Diag pane (non-destructive)
    (~guiLP.notNil).if({
        ~guiLP.sendPaneText(\diag, "Next: " ++ canonText.asString)
    });
};

// Public one-liners
~nav_show  = { showNow.value };
~nav_fret  = { arg fret; ~cm.builder.navigateByFret(nil, fret); showNow.value };
~nav_reset = { ~cm.builder.resetNavigation; showNow.value };

// Initial smoke
"Ready: ~nav_fret.(3), ~nav_fret.(5), ~nav_fret.(7) … ; and ~nav_reset.()".postln;
~nav_show.();

// Progress (in-memory only; no file I/O)
~md_progress = (~md_progress ? List.new).add("Sprint3 fixed: nav smoke v0.1.1 @ " ++ Date.localtime.stamp);
)