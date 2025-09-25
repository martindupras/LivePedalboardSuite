/////////////////////////////////////////////////////////////
// SixPanes_GridLayout_MeterSim.scd
// v0.2.0
// MD 2025-09-25 13:55
//
// Purpose / Style:
// - GUI-only: 6 panes in GridLayout (3x2); top-left pane contains a simulated meter.
// - No audio, no Ndefs. Pure Qt UI.
// - Rules: var-first; descriptive lowercase names; no non-local returns; known-good SC syntax.
/////////////////////////////////////////////////////////////

(
var window, windowRect, windowBg, paneFill;
var titleFont, bodyFont, paneColors, paneTitles;
var makePane, makePaneWithMeter, p;
var meterView, meterRoutine;

// ---------- close prior MagicDisplayGUI windows ----------
Window.allWindows.do({ |w| var nameString; nameString = w.name.asString; if(nameString.beginsWith("MagicDisplayGUI"), { { w.close }.defer }); });

// ---------- window & styles ----------
windowRect = Rect(80, 60, 1200, 850);
window = Window("MagicDisplayGUI GridLayout + Sim Meter", windowRect).alwaysOnTop_(true);
windowBg = Color(0.08, 0.08, 0.09);
paneFill = Color(0.15, 0.15, 0.18);
window.view.background_(windowBg);

titleFont = Font("Helvetica-Bold", 16);
bodyFont  = Font("Menlo", 12);
paneColors = [Color.red, Color.green, Color.blue, Color.yellow, Color.magenta, Color.cyan];
paneTitles = ["top-left","top-right","middle-left","middle-right","bottom-left","bottom-right"];

p = Array.newClear(6);

// ---------- factories ----------
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
    bodyText  = StaticText().string_("Pane: " ++ titleString ++ "\nGUI-only layout test.").font_(bodyFont).stringColor_(Color(0.85,0.9,0.95));
    textColumn = UserView();
    textColumn.layout_(VLayout(UserView().minHeight_(6), titleText, UserView().minHeight_(4), bodyText, nil));
    pane.layout_(VLayout(UserView().minHeight_(6), textColumn, nil));
    pane
};

makePaneWithMeter = { |titleString, borderColor|
    var pane, titleText, bodyText, textColumn, meterBox;
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
    bodyText  = StaticText().string_("Pane: " ++ titleString ++ "\nSimulated meter on the right.").font_(bodyFont).stringColor_(Color(0.85,0.9,0.95));
    meterView = LevelIndicator().warning_(0.7).critical_(0.95).minSize_(Size(18, 180));
    textColumn = UserView().layout_(VLayout(UserView().minHeight_(6), titleText, UserView().minHeight_(4), bodyText, nil));
    meterBox   = UserView().layout_(VLayout(UserView().minHeight_(6), meterView, nil));
    pane.layout_(HLayout(UserView().minWidth_(6), textColumn, UserView().minWidth_(10), meterBox, UserView().minWidth_(6)));
    pane
};

// ---------- build six panes (index 0 gets the meter) ----------
p[0] = makePaneWithMeter.(paneTitles[0], paneColors[0]); // top-left with meter
p[1] = makePane.(paneTitles[1], paneColors[1]);
p[2] = makePane.(paneTitles[2], paneColors[2]);
p[3] = makePane.(paneTitles[3], paneColors[3]);
p[4] = makePane.(paneTitles[4], paneColors[4]);
p[5] = makePane.(paneTitles[5], paneColors[5]);

// ---------- install grid 3x2 ----------
window.layout_(GridLayout.rows(
    [ p[0], p[1] ],
    [ p[2], p[3] ],
    [ p[4], p[5] ]
));
window.front;

// ---------- simulated meter animation (no audio) ----------
meterRoutine = Routine({
    var updateInterval, phase, val, noise;
    updateInterval = 0.05;
    phase = 0.0;
    loop {
        val = ((sin(phase) + 1.0) * 0.5).linlin(0.0, 1.0, 0.05, 0.92);
        noise = (0.10.rand2).clip(-0.08, 0.08);
        val = (val + noise).clip(0.0, 1.0);
        { if(meterView.notNil, { meterView.value_(val) }) }.defer;
        phase = phase + 0.15;
        updateInterval.wait;
    }
}).play(AppClock);

// ---------- cleanup ----------
window.onClose_({
    if(meterRoutine.notNil, { meterRoutine.stop });
});
)
