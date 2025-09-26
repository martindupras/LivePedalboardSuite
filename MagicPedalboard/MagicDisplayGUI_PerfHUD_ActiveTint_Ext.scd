// MagicDisplayGUI_PerfHUD_ActiveTint_Ext.scd
// v0.1.0
// MD 2025-09-26 15:36 BST

/* Purpose
   Keep the Chain A/B panel backgrounds in sync with ~md_currentChain (solid green).
   - Finds the A/B panels by locating "Chain A"/"Chain B" StaticText labels.
   - var-first; descriptive lowercase; AppClock-only; no server.sync.
*/

(
~md_findHudPanels = {
    var windowRef, collectViews, allViews, panelForLabel, aPanel, bPanel;

    windowRef = Window.allWindows.detect({ arg w;
        var nameString;
        nameString = w.tryPerform(\name);
        nameString.notNil and: { nameString.asString.beginsWith("MagicDisplayGUI") }
    });
    if(windowRef.isNil) { ^[nil, nil] };

    collectViews = { arg rootView, list;
        var children;
        children = rootView.children ? [];
        children.do({ arg c; list.add(c); collectViews.(c, list) });
        list
    };

    allViews = collectViews.(windowRef.view, List.new);

    panelForLabel = { arg labelString;
        var labelView, panelView;
        labelView = allViews.detect({ arg v; v.isKindOf(StaticText) and: { v.string == labelString } });
        panelView = labelView.notNil.if({ labelView.parent }, { nil });
        panelView
    };

    aPanel = panelForLabel.("Chain A");
    bPanel = panelForLabel.("Chain B");
    [aPanel, bPanel]
};

~md_startActiveTintOverlay = {
    var panels, aPanel, bPanel, winRef, routine, activeColor, idleColor;

    panels = ~md_findHudPanels.();
    aPanel = panels[0]; bPanel = panels[1];

    if(aPanel.isNil or: { bPanel.isNil }) {
        "⚠️ Could not locate Chain A/B panels; tint overlay not installed.".warn;
        ^nil
    };

    winRef = aPanel.window;
    activeColor = Color(0.18, 0.28, 0.18);
    idleColor   = Color.grey(0.15);

    routine = Routine({
        var keepRunning, isA, isB;
        keepRunning = true;
        while({ keepRunning and: { winRef.notNil and: { winRef.isClosed.not } } }, {
            isA = (~md_currentChain ? \A) == \A;
            isB = (~md_currentChain ? \A) == \B;
            aPanel.background_( isA.if({ activeColor }, { idleColor }) );
            bPanel.background_( isB.if({ activeColor }, { idleColor }) );
            0.15.wait;
        });
    }).play(AppClock);

    "[HUD] ACTIVE tint overlay running (current=" ++ (~md_currentChain ? \A).asString ++ ")".postln;
    routine
};
)
