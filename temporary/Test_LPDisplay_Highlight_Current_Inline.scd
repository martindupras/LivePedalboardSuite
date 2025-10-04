// Test_LPDisplay_Highlight_Current_Inline.scd
// v0.1.0
// MD 20251004-1616

/*
Purpose (TEMP)
- Add an inline-only ACTIVE/NEXT visual to LPDisplayLayoutWindow without changing class files.
- Highlight ACTIVE pane (brighter green), dim NEXT pane (darker).
- Rewrite top titles to "Chain A ACTIVE — …" / "Chain B NEXT — …".
- Provide ~lp_markActive.(\A|\B) to flip state (e.g. after /switch).

Style
- var-first; tilde vars; AppClock.defer for UI; no server.sync.
*/

(
var findLabelByAny, setLabelString, setPaneBg, splitSummary, applyVisuals, detectActive, applyFromCurrent,
    labelA, labelB, paneA, paneB, activeColor, nextColor, textBright, textDim, ac;

// --- colors & text tints ---
activeColor = Color.fromHexString("#2ecc71");   // brighter green
nextColor   = Color.fromHexString("#2c3e50");   // dark slate
textBright  = Color.white;
textDim     = Color.fromHexString("#bdc3c7");

// --- helpers: find top pane title labels ("Top Left Pane"/"Top Right Pane"/renamed) ---
findLabelByAny = { |cands|
    var found = nil;
    var scan;
    scan = { |view|
        view.children.do({ |ch|
            if(ch.isKindOf(StaticText) and: { cands.any({ |s| ch.string.asString == s.asString }) }) {
                found = ch;
            }{
                scan.(ch);
            };
        });
    };
    Window.allWindows.do({ |w| if((w.tryPerform(\name) ? "") == "Layout Test") { scan.(w.view) } });
    found
};

setLabelString = { |labelObj, str, color|
    if(labelObj.notNil) {
        { labelObj.string_(str.asString); if(color.notNil) { labelObj.stringColor_(color) } }.defer;
    };
};

setPaneBg = { |paneView, col|
    if(paneView.notNil and: { paneView.respondsTo(\background_) }) {
        { paneView.background_(col) }.defer;
    };
};

// Extract the "— summary" part from an existing label if present
splitSummary = { |labelObj|
    var s, idx;
    s = (labelObj ? "").asString;
    idx = s.find("—");
    (idx.notNil).if({ s.copyRange(idx+1, s.size-1).trim }, { "" })
};

// Apply visuals (colors + titles) for ACTIVE = \A or \B
applyVisuals = { |activeWhich|
    var activeIsA = (activeWhich.asSymbol == \A);
    var summA = splitSummary.(labelA);  // keep any existing "src | procs | sink" text
    var summB = splitSummary.(labelB);

    // pane views = parent of the title labels
    paneA = (labelA.notNil).if({ labelA.parent }, { nil });
    paneB = (labelB.notNil).if({ labelB.parent }, { nil });

    // colors
    setPaneBg.(paneA, activeIsA.if(activeColor, nextColor));
    setPaneBg.(paneB, activeIsA.if(nextColor,   activeColor));
    setLabelString.(labelA, (activeIsA.if("Chain A ACTIVE", "Chain A NEXT")
        ++ (summA.size>0).if({ " — "++summA }, { "" })), activeIsA.if(textBright, textDim));
    setLabelString.(labelB, (activeIsA.if("Chain B NEXT",   "Chain B ACTIVE")
        ++ (summB.size>0).if({ " — "++summB }, { "" })), activeIsA.if(textDim, textBright));
    ("LPDisplay panes marked: ACTIVE=" ++ activeWhich).postln;
};

// Try to detect the active chain quickly (prefer shared state from adapter bridge)
detectActive = {
    // 1) If adapter bridge toggled ~md_currentChain, reuse it.
    var ac = ~md_currentChain ? \A;
    // 2) If not present, assume \A immediately after bring-up.
    ac
};

// ---- run once ----
labelA = findLabelByAny.(["Top Left Pane","Chain A"]);
labelB = findLabelByAny.(["Top Right Pane","Chain B"]);
if(labelA.isNil or: { labelB.isNil }) {
    "Could not locate LPDisplay top pane labels. Open 'Layout Test' first.".warn;
    ^nil;
};

// mark current on load
applyFromCurrent = {
    ac = detectActive.();
    applyVisuals.(ac);
};
applyFromCurrent.();

// expose a quick toggle for later use (e.g. after /switch)
~lp_markActive = { |which=\A| applyVisuals.(which) };

"OK (TEMP): ACTIVE/NEXT visuals installed; use ~lp_markActive.(\\A) or .(\\B).".postln;
nil
)