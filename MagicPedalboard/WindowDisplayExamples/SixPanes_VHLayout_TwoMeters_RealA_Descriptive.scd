/////////////////////////////////////////////////////////////
// SixPanes_VHLayout_TwoMeters_RealA_Descriptive.scd
// v0.5.0
// MD 2025-09-25 14:54
//
// Purpose / Style:
// - GUI-only layout (VLayout + HLayout) with two meters in the top row.
// - Meter A (top-left) shows a real level from a tiny Ndef test source.
// - Meter B (top-right) is simulated (sine + noise) to verify GUI update path.
// - Rules: var-first; descriptive lowercase names; no single-letter variables; no non-local returns; no server.sync.
// - Cleans up Ndef and buses on window close.
/////////////////////////////////////////////////////////////

(
var window, windowRect, windowBackgroundColor, paneFillColor, cellPadding;
var titleFont, bodyFont, paneBorderColors, paneTitles;
var buildTextPane, buildMeterPane, rowTop, rowMiddle, rowBottom, rootLayout;

var meterViewA, meterViewB, meterRoutine;           // GUI meter widgets + updater
var serverBootRoutine;                               // guard: keep GUI responsive
var amplitudeBusA;                                   // control bus for real meter A
var meterLabelFont;                                  // tiny label above meters

// ---------- close prior MagicDisplayGUI windows ----------
Window.allWindows.do({ |existingWindow|
    var existingNameString;
    existingNameString = existingWindow.name.asString;
    if(existingNameString.beginsWith("MagicDisplayGUI"), { { existingWindow.close }.defer });
});

// ---------- window & styles ----------
windowRect = Rect(80, 60, 1200, 850);
window = Window("MagicDisplayGUI VH + Real A / Sim B", windowRect).alwaysOnTop_(true);
windowBackgroundColor = Color(0.08, 0.08, 0.09);
paneFillColor = Color(0.15, 0.15, 0.18);
window.view.background_(windowBackgroundColor);
cellPadding = 10;

titleFont = Font("Helvetica-Bold", 16);
bodyFont  = Font("Menlo", 12);
meterLabelFont = Font("Helvetica-Bold", 13);

paneBorderColors = [Color.red, Color.green, Color.blue, Color.yellow, Color.magenta, Color.cyan];
paneTitles = ["top-left","top-right","middle-left","middle-right","bottom-left","bottom-right"];

// ---------- factories ----------
// Text-only pane
buildTextPane = { |paneTitleString, borderColor|
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

    titleTextView = StaticText()
        .string_(paneTitleString)
        .font_(titleFont)
        .stringColor_(Color.white);

    bodyTextView  = StaticText()
        .string_("Pane: " ++ paneTitleString ++ "\nGUI-only layout test.")
        .font_(bodyFont)
        .stringColor_(Color(0.85, 0.9, 0.95));

    textColumnView = UserView().layout_(VLayout(
        UserView().minHeight_(6),
        titleTextView,
        UserView().minHeight_(4),
        bodyTextView,
        nil
    ));

    paneView.layout_(VLayout(
        UserView().minHeight_(6),
        textColumnView,
        nil
    ));

    paneView
};

// Pane with meter and label (labelTextString = "A" or "B")
// Returns: the pane view; assigns meterViewA/meterViewB internally
buildMeterPane = { |paneTitleString, borderColor, labelTextString|
    var paneView, titleTextView, bodyTextView, textColumnView;
    var meterLabelView, meterColumnView, localMeterView;

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

    titleTextView = StaticText()
        .string_(paneTitleString)
        .font_(titleFont)
        .stringColor_(Color.white);

    bodyTextView  = StaticText()
        .string_("Pane: " ++ paneTitleString ++ "\nMeter " ++ labelTextString ++ " is shown on the right.")
        .font_(bodyFont)
        .stringColor_(Color(0.85, 0.9, 0.95));

    textColumnView = UserView().layout_(VLayout(
        UserView().minHeight_(6),
        titleTextView,
        UserView().minHeight_(4),
        bodyTextView,
        nil
    ));

    meterLabelView = StaticText()
        .string_(labelTextString)
        .font_(meterLabelFont)
        .stringColor_(Color.white)
        .align_(\center);

    localMeterView = LevelIndicator()
        .warning_(0.7)
        .critical_(0.95)
        .minSize_(Size(20, 180));

    if(labelTextString == "A", { meterViewA = localMeterView }, { meterViewB = localMeterView });

    meterColumnView = UserView().layout_(VLayout(
        UserView().minHeight_(4),
        meterLabelView,
        UserView().minHeight_(4),
        localMeterView,
        nil
    ));

    paneView.layout_(HLayout(
        UserView().minWidth_(6),
        textColumnView,
        UserView().minWidth_(10),
        meterColumnView,
        UserView().minWidth_(6)
    ));

    paneView
};

// ---------- build rows (top row uses meters) ----------
rowTop = HLayout(
    buildMeterPane.(paneTitles[0], paneBorderColors[0], "A"), // top-left: meter A (real)
    UserView().minWidth_(cellPadding),
    buildMeterPane.(paneTitles[1], paneBorderColors[1], "B")  // top-right: meter B (simulated)
);

rowMiddle = HLayout(
    buildTextPane.(paneTitles[2], paneBorderColors[2]),
    UserView().minWidth_(cellPadding),
    buildTextPane.(paneTitles[3], paneBorderColors[3])
);

rowBottom = HLayout(
    buildTextPane.(paneTitles[4], paneBorderColors[4]),
    UserView().minWidth_(cellPadding),
    buildTextPane.(paneTitles[5], paneBorderColors[5])
);

// ---------- root layout ----------
rootLayout = VLayout(
    UserView().minHeight_(cellPadding),
    rowTop,
    UserView().minHeight_(cellPadding),
    rowMiddle,
    UserView().minHeight_(cellPadding),
    rowBottom,
    UserView().minHeight_(cellPadding)
);

window.layout_(rootLayout);
window.front;

// ---------- bring up real meter A (Ndef) and simulated meter B ----------
serverBootRoutine = Routine({
    var updateIntervalSeconds, phaseB, simulatedValueB, simulatedNoiseB;

    // 1) Boot + minimal server prep
    s.waitForBoot({
        var defaultNumChannels;
        defaultNumChannels = 2;

        s.initTree;
        s.defaultGroup.freeAll;

        // 2) Control bus for meter A
        amplitudeBusA = Bus.control(s, 1);

        // 3) Tiny test source -> real meter A (no OutputProxy indexing; no server.sync)
        Ndef(\meterSourceA, {
            var leftFrequency, rightFrequency, stereoSignal, monoSignal, amplitudeValue;
            var meterBusIndex;
            leftFrequency  = 220 + LFTri.kr(0.10).range(-20,  20);
            rightFrequency = 330 + LFTri.kr(0.13).range(-30,  30);
            stereoSignal   = [Saw.ar(leftFrequency), Saw.ar(rightFrequency)] * 0.07;
            monoSignal     = stereoSignal.sum * 0.5;
            amplitudeValue = Amplitude.ar(monoSignal, 0.01, 0.30).clip(0.0, 1.5);
            meterBusIndex  = \meterBus.kr(0);   // language sets this before/around play
            Out.kr(meterBusIndex, amplitudeValue);
            (stereoSignal.tanh * 0.9)
        });

        // set meter bus, then play quietly to out
        Ndef(\meterSourceA).set(\meterBus, amplitudeBusA.index);
        Ndef(\meterSourceA).play;
    });

    // 4) Update both meters on AppClock (A from control bus, B simulated)
    updateIntervalSeconds = 0.05;
    phaseB = 0.0;

    meterRoutine = Routine({
        loop {
            // real meter A (read from control bus written by Ndef)
            amplitudeBusA.get({ |busValueA|
                var mappedValueA;
                mappedValueA = busValueA.clip(0.0, 1.0);
                { if(meterViewA.notNil, { meterViewA.value_(mappedValueA) }) }.defer;
            });

            // simulated meter B (sine + noise)
            simulatedValueB = ((sin(phaseB) + 1.0) * 0.5).linlin(0.0, 1.0, 0.05, 0.92);
            simulatedNoiseB = (0.10.rand2).clip(-0.08, 0.08);
            simulatedValueB = (simulatedValueB + simulatedNoiseB).clip(0.0, 1.0);
            { if(meterViewB.notNil, { meterViewB.value_(simulatedValueB) }) }.defer;

            phaseB = phaseB + 0.12;
            updateIntervalSeconds.wait;
        }
    }).play(AppClock);
}).play(AppClock);

// ---------- cleanup ----------
window.onClose_({
    if(meterRoutine.notNil, { meterRoutine.stop });
    if(serverBootRoutine.notNil, { serverBootRoutine.stop });
    if(amplitudeBusA.notNil, { amplitudeBusA.free });
    if(Ndef.all.at(\meterSourceA).notNil, {
        Ndef(\meterSourceA).stop;
        Ndef(\meterSourceA).clear;
    });
});
)
