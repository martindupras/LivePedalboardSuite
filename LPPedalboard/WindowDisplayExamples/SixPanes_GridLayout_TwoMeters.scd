/////////////////////////////////////////////////////////////
// SixPanes_GridLayout_TwoMeters.scd
// v0.3.1
// MD 2025-09-25 14:20
//
// Purpose / Style:
// - GUI-only: 6 panes in a GridLayout (3x2).
// - Top-left and top-right contain simulated meters (no audio).
// - Rules: var-first; descriptive lowercase names; no non-local returns; known-good SC syntax.
/////////////////////////////////////////////////////////////

(
var window, windowRect, windowBg, paneFill;
var titleFont, bodyFont, paneColors, paneTitles;
var makeTextPane, makeMeterPane, p;
var meterViewA, meterViewB, meterRoutine;

// ---------- close prior MagicDisplayGUI windows ----------
Window.allWindows.do({ |w|
    var nameString;
    nameString = w.name.asString;
    if(nameString.beginsWith("MagicDisplayGUI"), { { w.close }.defer });
});

// ---------- window & styles ----------
windowRect = Rect(80, 60, 1200, 850);
window = Window("MagicDisplayGUI GridLayout + Two Sim Meters", windowRect).alwaysOnTop_(true);
windowBg = Color(0.08, 0.08, 0.09);
paneFill = Color(0.15, 0.15, 0.18);
window.view.background_(windowBg);

titleFont = Font("Helvetica-Bold", 16);
bodyFont  = Font("Menlo", 12);
paneColors = [Color.red, Color.green, Color.blue, Color.yellow, Color.magenta, Color.cyan];
paneTitles = ["top-left","top-right","middle-left","middle-right","bottom-left","bottom-right"];

// ---------- factories ----------
makeTextPane = { |titleString, borderColor|
    var pane, titleText, bodyText, textColumn;
    pane = UserView().background_(paneFill).minSize_(Size(520, 230));
    pane.drawFunc = { |v|
        var r;
        r = Rect(1, 1, v.bounds.width - 2, v.bounds.height - 2);
        Pen.fillColor = Color(0.11, 0.11, 0.12);
        Pen.strokeColor = borderColor;
        Pen.width = 2;
        Pen.fillRect(r);
        Pen.strokeRect(r);
    };
    titleText = StaticText().string_(titleString).font_(titleFont).stringColor_(Color.white);
    bodyText  = StaticText().string_("Pane: " ++ titleString ++ "\nGUI-only layout test.")
        .font_(bodyFont).stringColor_(Color(0.85,0.9,0.95));
    textColumn = UserView().layout_(VLayout(UserView().minHeight_(6), titleText, UserView().minHeight_(4), bodyText, nil));
    pane.layout_(VLayout(UserView().minHeight_(6), textColumn, nil));
    pane
};

// returns [pane, meterView]
makeMeterPane = { |titleString, borderColor|
    var pane, titleText, bodyText, textColumn, meterBox, meterView;
    pane = UserView().background_(paneFill).minSize_(Size(520, 230));
    pane.drawFunc = { |v|
        var r;
        r = Rect(1, 1, v.bounds.width - 2, v.bounds.height - 2);
        Pen.fillColor = Color(0.11, 0.11, 0.12);
        Pen.strokeColor = borderColor;
        Pen.width = 2;
        Pen.fillRect(r);
        Pen.strokeRect(r);
    };
    titleText = StaticText().string_(titleString).font_(titleFont).stringColor_(Color.white);
    bodyText  = StaticText().string_("Pane: " ++ titleString ++ "\nSimulated meter on the right.")
        .font_(bodyFont).stringColor_(Color(0.85,0.9,0.95));
    meterView = LevelIndicator().warning_(0.7).critical_(0.95).minSize_(Size(18, 180));
    textColumn = UserView().layout_(VLayout(UserView().minHeight_(6), titleText, UserView().minHeight_(4), bodyText, nil));
    meterBox   = UserView().layout_(VLayout(UserView().minHeight_(6), meterView, nil));
    pane.layout_(HLayout(UserView().minWidth_(6), textColumn, UserView().minWidth_(10), meterBox, UserView().minWidth_(6)));
    [pane, meterView]
};

// ---------- build six panes ----------
p = Array.newClear(6);
var pane, m;

#pane, m = makeMeterPane.(paneTitles[0], paneColors[0]); p[0] = pane; meterViewA = m; // top-left
#pane, m = makeMeterPane.(paneTitles[1], paneColors[1]); p[1] = pane; meterViewB = m; // top-right
p[2] = makeTextPane.(paneTitles[2], paneColors[2]);
p[3] = makeTextPane.(paneTitles[3], paneColors[3]);
p[4] = makeTextPane.(paneTitles[4], paneColors[4]);
p[5] = makeTextPane.(paneTitles[5], paneColors[5]);

// ---------- grid layout 3x2 ----------
window.layout_(GridLayout.rows(
    [ p[0], p[1] ],
    [ p[2], p[3] ],
    [ p[4], p[5] ]
));
window.front;

// ---------- simulated meters (single routine updates both) ----------
meterRoutine = Routine({
    var updateInterval, phaseA, phaseB, valA, valB, noiseA, noiseB;
    updateInterval = 0.05;
    phaseA = 0.0; phaseB = 0.9;
    loop {
        valA = ((sin(phaseA) + 1.0) * 0.5).linlin(0.0, 1.0, 0.05, 0.92);
        valB = ((sin(phaseB) + 1.0) * 0.5).linlin(0.0, 1.0, 0.05, 0.92);
        noiseA = (0.10.rand2).clip(-0.08, 0.08);
        noiseB = (0.10.rand2).clip(-0.08, 0.08);
        valA = (valA + noiseA).clip(0.0, 1.0);
        valB = (valB + noiseB).clip(0.0, 1.0);
        {
            if(meterViewA.notNil, { meterViewA.value_(valA) });
            if(meterViewB.notNil, { meterViewB.value_(valB) });
        }.defer;
        phaseA = phaseA + 0.15;
        phaseB = phaseB + 0.11;
        updateInterval.wait;
    }
}).play(AppClock);

// ---------- cleanup ----------
window.onClose_({
    if(meterRoutine.notNil, { meterRoutine.stop });
});
)
