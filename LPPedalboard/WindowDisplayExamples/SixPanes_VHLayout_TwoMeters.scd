/////////////////////////////////////////////////////////////
// SixPanes_VHLayout_TwoMeters.scd
// v0.3.0
// MD 2025-09-25 14:08
//
// Purpose / Style:
// - GUI-only: 6 panes arranged with VLayout/HLayout; top-left and top-right contain simulated meters.
// - No audio, no Ndefs. Pure Qt UI.
// - Rules: var-first; descriptive lowercase names; no non-local returns; known-good SC syntax.
/////////////////////////////////////////////////////////////

(
var window, windowRect, windowBg, paneFill, cellPadding;
var titleFont, bodyFont, paneColors, paneTitles;
var makePane, makePaneWithMeter, row1, row2, row3, rootLayout;
var meterViews, meterRoutine;

// ---------- close prior MagicDisplayGUI windows ----------
Window.allWindows.do({ |w|
    var nameString;
    nameString = w.name.asString;
    if(nameString.beginsWith("MagicDisplayGUI"), { { w.close }.defer });
});

// ---------- window & styles ----------
windowRect = Rect(80, 60, 1200, 850);
window = Window("MagicDisplayGUI VHLayout + Two Sim Meters", windowRect).alwaysOnTop_(true);
windowBg = Color(0.08, 0.08, 0.09);
paneFill = Color(0.15, 0.15, 0.18);
window.view.background_(windowBg);
cellPadding = 10;

titleFont = Font("Helvetica-Bold", 16);
bodyFont  = Font("Menlo", 12);

paneColors = [Color.red, Color.green, Color.blue, Color.yellow, Color.magenta, Color.cyan];
paneTitles = ["top-left","top-right","middle-left","middle-right","bottom-left","bottom-right"];

// store two meter views [A, B]
meterViews = Array.newClear(2);

// ---------- pane factories ----------
// Plain pane (no meter)
makePane = { |titleString, borderColor|
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
    bodyText  = StaticText()
        .string_("Pane: " ++ titleString ++ "\nGUI-only layout test.")
        .font_(bodyFont).stringColor_(Color(0.85, 0.9, 0.95));

    textColumn = UserView();
    textColumn.layout_(VLayout(
        UserView().minHeight_(6),
        titleText,
        UserView().minHeight_(4),
        bodyText,
        nil
    ));

    pane.layout_(VLayout(
        UserView().minHeight_(6),
        textColumn,
        nil
    ));

    pane
};

// Pane with meter; meterIndex: 0 for top-left (A), 1 for top-right (B)
makePaneWithMeter = { |titleString, borderColor, meterIndex|
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
    bodyText  = StaticText()
        .string_("Pane: " ++ titleString ++ "\nSimulated meter on the right.")
        .font_(bodyFont).stringColor_(Color(0.85, 0.9, 0.95));

    textColumn = UserView();
    textColumn.layout_(VLayout(
        UserView().minHeight_(6),
        titleText,
        UserView().minHeight_(4),
        bodyText,
        nil
    ));

    // vertical level indicator
    meterView = LevelIndicator()
        .warning_(0.7).critical_(0.95)
        .minSize_(Size(18, 180));

    meterViews.put(meterIndex, meterView);

    meterBox = UserView();
    meterBox.layout_(VLayout(
        UserView().minHeight_(6),
        meterView,
        nil
    ));

    pane.layout_(HLayout(
        UserView().minWidth_(6),
        textColumn,
        UserView().minWidth_(10), // spacer between text and meter
        meterBox,
        UserView().minWidth_(6)
    ));

    pane
};

// ---------- build rows (top-left & top-right use meters) ----------
row1 = HLayout(
    makePaneWithMeter.(paneTitles[0], paneColors[0], 0), // top-left meter A
    UserView().minWidth_(cellPadding),
    makePaneWithMeter.(paneTitles[1], paneColors[1], 1)  // top-right meter B
);

row2 = HLayout(
    makePane.(paneTitles[2], paneColors[2]),
    UserView().minWidth_(cellPadding),
    makePane.(paneTitles[3], paneColors[3])
);

row3 = HLayout(
    makePane.(paneTitles[4], paneColors[4]),
    UserView().minWidth_(cellPadding),
    makePane.(paneTitles[5], paneColors[5])
);

// ---------- root layout ----------
rootLayout = VLayout(
    UserView().minHeight_(cellPadding),
    row1,
    UserView().minHeight_(cellPadding),
    row2,
    UserView().minHeight_(cellPadding),
    row3,
    UserView().minHeight_(cellPadding)
);
window.layout_(rootLayout);
window.front;

// ---------- simulated meters (single AppClock routine for both) ----------
meterRoutine = Routine({
    var updateInterval, phaseA, phaseB, valA, valB, noiseA, noiseB;
    updateInterval = 0.05;
    phaseA = 0.0; phaseB = 1.2; // offset so A and B differ
    loop {
        valA = ((sin(phaseA) + 1.0) * 0.5).linlin(0.0, 1.0, 0.05, 0.92);
        valB = ((sin(phaseB) + 1.0) * 0.5).linlin(0.0, 1.0, 0.05, 0.92);
        noiseA = (0.10.rand2).clip(-0.08, 0.08);
        noiseB = (0.10.rand2).clip(-0.08, 0.08);
        valA = (valA + noiseA).clip(0.0, 1.0);
        valB = (valB + noiseB).clip(0.0, 1.0);
        {
            if(meterViews[0].notNil, { meterViews[0].value_(valA) });
            if(meterViews[1].notNil, { meterViews[1].value_(valB) });
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
