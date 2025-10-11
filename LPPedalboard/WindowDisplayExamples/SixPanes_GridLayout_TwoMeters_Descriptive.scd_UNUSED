/////////////////////////////////////////////////////////////
// SixPanes_GridLayout_TwoMeters_Descriptive.scd
// v0.4.0
// MD 2025-09-25 14:36
//
// Purpose / Style:
// - GUI-only: 6 panes arranged with GridLayout; top-left and top-right have simulated meters.
// - Rules: var-first; descriptive lowercase variable names; no single-letter variables; no non-local returns.
// - No audio, no Ndefs.
/////////////////////////////////////////////////////////////

(
var window, windowRect, windowBackgroundColor, paneFillColor;
var titleFont, bodyFont, paneBorderColors, paneTitles;
var makeTextPane, makeMeterPaneForKey, paneArray;
var meterViewA, meterViewB, meterRoutine;

// ---------- close prior MagicDisplayGUI windows ----------
Window.allWindows.do({ |existingWindow|
    var nameString;
    nameString = existingWindow.name.asString;
    if(nameString.beginsWith("MagicDisplayGUI"), { { existingWindow.close }.defer });
});

// ---------- window & styles ----------
windowRect = Rect(80, 60, 1200, 850);
window = Window("MagicDisplayGUI GridLayout + Two Sim Meters", windowRect).alwaysOnTop_(true);
windowBackgroundColor = Color(0.08, 0.08, 0.09);
paneFillColor = Color(0.15, 0.15, 0.18);
window.view.background_(windowBackgroundColor);

titleFont = Font("Helvetica-Bold", 16);
bodyFont  = Font("Menlo", 12);
paneBorderColors = [Color.red, Color.green, Color.blue, Color.yellow, Color.magenta, Color.cyan];
paneTitles = ["top-left","top-right","middle-left","middle-right","bottom-left","bottom-right"];

// ---------- factories ----------
makeTextPane = { |paneTitleString, borderColor|
    var paneView, titleTextView, bodyTextView, textColumnView;
    paneView = UserView().background_(paneFillColor).minSize_(Size(520, 230));
    paneView.drawFunc = { |drawView|
        var borderRect;
        borderRect = Rect(1, 1, drawView.bounds.width - 2, drawView.bounds.height - 2);
        Pen.fillColor = Color(0.11, 0.11, 0.12);
        Pen.strokeColor = borderColor;
        Pen.width = 2;
        Pen.fillRect(borderRect);
        Pen.strokeRect(borderRect);
    };
    titleTextView = StaticText().string_(paneTitleString).font_(titleFont).stringColor_(Color.white);
    bodyTextView  = StaticText().string_("Pane: " ++ paneTitleString ++ "\nGUI-only layout test.")
        .font_(bodyFont).stringColor_(Color(0.85, 0.9, 0.95));
    textColumnView = UserView().layout_(VLayout(UserView().minHeight_(6), titleTextView, UserView().minHeight_(4), bodyTextView, nil));
    paneView.layout_(VLayout(UserView().minHeight_(6), textColumnView, nil));
    paneView
};

// Meter pane; meterKeySymbol is \A or \B
makeMeterPaneForKey = { |paneTitleString, borderColor, meterKeySymbol|
    var paneView, titleTextView, bodyTextView, textColumnView, meterColumnView, localMeterView;
    paneView = UserView().background_(paneFillColor).minSize_(Size(520, 230));
    paneView.drawFunc = { |drawView|
        var borderRect;
        borderRect = Rect(1, 1, drawView.bounds.width - 2, drawView.bounds.height - 2);
        Pen.fillColor = Color(0.11, 0.11, 0.12);
        Pen.strokeColor = borderColor;
        Pen.width = 2;
        Pen.fillRect(borderRect);
        Pen.strokeRect(borderRect);
    };
    titleTextView = StaticText().string_(paneTitleString).font_(titleFont).stringColor_(Color.white);
    bodyTextView  = StaticText().string_("Pane: " ++ paneTitleString ++ "\nSimulated meter on the right.")
        .font_(bodyFont).stringColor_(Color(0.85, 0.9, 0.95));
    textColumnView = UserView().layout_(VLayout(UserView().minHeight_(6), titleTextView, UserView().minHeight_(4), bodyTextView, nil));
    localMeterView = LevelIndicator().warning_(0.7).critical_(0.95).minSize_(Size(18, 180));
    if(meterKeySymbol == \A, { meterViewA = localMeterView }, { meterViewB = localMeterView });
    meterColumnView = UserView().layout_(VLayout(UserView().minHeight_(6), localMeterView, nil));
    paneView.layout_(HLayout(UserView().minWidth_(6), textColumnView, UserView().minWidth_(10), meterColumnView, UserView().minWidth_(6)));
    paneView
};

// ---------- build six panes ----------
paneArray = Array.newClear(6);
paneArray[0] = makeMeterPaneForKey.(paneTitles[0], paneBorderColors[0], \A); // top-left with meter A
paneArray[1] = makeMeterPaneForKey.(paneTitles[1], paneBorderColors[1], \B); // top-right with meter B
paneArray[2] = makeTextPane.(paneTitles[2], paneBorderColors[2]);
paneArray[3] = makeTextPane.(paneTitles[3], paneBorderColors[3]);
paneArray[4] = makeTextPane.(paneTitles[4], paneBorderColors[4]);
paneArray[5] = makeTextPane.(paneTitles[5], paneBorderColors[5]);

// ---------- grid layout 3x2 ----------
window.layout_(GridLayout.rows(
    [ paneArray[0], paneArray[1] ],
    [ paneArray[2], paneArray[3] ],
    [ paneArray[4], paneArray[5] ]
));
window.front;

// ---------- simulated meters (single routine updates both) ----------
meterRoutine = Routine({
    var updateIntervalSeconds, phaseA, phaseB, valueA, valueB, noiseA, noiseB;
    updateIntervalSeconds = 0.05;
    phaseA = 0.0; phaseB = 0.9;
    loop {
        valueA = ((sin(phaseA) + 1.0) * 0.5).linlin(0.0, 1.0, 0.05, 0.92);
        valueB = ((sin(phaseB) + 1.0) * 0.5).linlin(0.0, 1.0, 0.05, 0.92);
        noiseA = (0.10.rand2).clip(-0.08, 0.08);
        noiseB = (0.10.rand2).clip(-0.08, 0.08);
        valueA = (valueA + noiseA).clip(0.0, 1.0);
        valueB = (valueB + noiseB).clip(0.0, 1.0);
        {
            if(meterViewA.notNil, { meterViewA.value_(valueA) });
            if(meterViewB.notNil, { meterViewB.value_(valueB) });
        }.defer;
        phaseA = phaseA + 0.15;
        phaseB = phaseB + 0.11;
        updateIntervalSeconds.wait;
    }
}).play(AppClock);

// ---------- cleanup ----------
window.onClose_({
    if(meterRoutine.notNil, { meterRoutine.stop });
});
)
