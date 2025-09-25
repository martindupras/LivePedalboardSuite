/////////////////////////////////////////////////////////////
// SixPanes_GridLayout_TwoMeters_RealA_Descriptive.scd
// v0.5.0
// MD 2025-09-25 14:54
//
// Purpose / Style:
// - GUI-only layout (GridLayout 3x2) with two meters in the top row.
// - Meter A (top-left) is real (Ndef test source -> control bus); Meter B (top-right) is simulated.
// - Rules: var-first; descriptive lowercase names; no single-letter variables; no non-local returns; no server.sync.
// - Cleans up Ndef and buses on window close.
/////////////////////////////////////////////////////////////

(
var window, windowRect, windowBackgroundColor, paneFillColor;
var titleFont, bodyFont, meterLabelFont, paneBorderColors, paneTitles;
var buildTextPane, buildMeterPane, paneArray;

var meterViewA, meterViewB, meterRoutine, serverBootRoutine;
var amplitudeBusA;

// ---------- close prior MagicDisplayGUI windows ----------
Window.allWindows.do({ |existingWindow|
    var existingNameString;
    existingNameString = existingWindow.name.asString;
    if(existingNameString.beginsWith("MagicDisplayGUI"), { { existingWindow.close }.defer });
});

// ---------- window & styles ----------
windowRect = Rect(80, 60, 1200, 850);
window = Window("MagicDisplayGUI Grid + Real A / Sim B", windowRect).alwaysOnTop_(true);
windowBackgroundColor = Color(0.08, 0.08, 0.09);
paneFillColor = Color(0.15, 0.15, 0.18);
window.view.background_(windowBackgroundColor);

titleFont = Font("Helvetica-Bold", 16);
bodyFont  = Font("Menlo", 12);
meterLabelFont = Font("Helvetica-Bold", 13);

paneBorderColors = [Color.red, Color.green, Color.blue, Color.yellow, Color.magenta, Color.cyan];
paneTitles = ["top-left","top-right","middle-left","middle-right","bottom-left","bottom-right"];

// ---------- factories ----------
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
    titleTextView = StaticText().string_(paneTitleString).font_(titleFont).stringColor_(Color.white);
    bodyTextView  = StaticText().string_("Pane: " ++ paneTitleString ++ "\nGUI-only layout test.")
        .font_(bodyFont).stringColor_(Color(0.85, 0.9, 0.95));
    textColumnView = UserView().layout_(VLayout(UserView().minHeight_(6), titleTextView, UserView().minHeight_(4), bodyTextView, nil));
    paneView.layout_(VLayout(UserView().minHeight_(6), textColumnView, nil));
    paneView
};

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
    titleTextView = StaticText().string_(paneTitleString).font_(titleFont).stringColor_(Color.white);
    bodyTextView  = StaticText().string_("Pane: " ++ paneTitleString ++ "\nMeter " ++ labelTextString ++ " is shown on the right.")
        .font_(bodyFont).stringColor_(Color(0.85, 0.9, 0.95));
    textColumnView = UserView().layout_(VLayout(UserView().minHeight_(6), titleTextView, UserView().minHeight_(4), bodyTextView, nil));
    meterLabelView = StaticText().string_(labelTextString).font_(meterLabelFont).stringColor_(Color.white).align_(\center);
    localMeterView = LevelIndicator().warning_(0.7).critical_(0.95).minSize_(Size(20, 180));
    if(labelTextString == "A", { meterViewA = localMeterView }, { meterViewB = localMeterView });
    meterColumnView = UserView().layout_(VLayout(UserView().minHeight_(4), meterLabelView, UserView().minHeight_(4), localMeterView, nil));
    paneView.layout_(HLayout(UserView().minWidth_(6), textColumnView, UserView().minWidth_(10), meterColumnView, UserView().minWidth_(6)));
    paneView
};

// ---------- build 3x2 grid: top row has meters ----------
paneArray = Array.newClear(6);
paneArray[0] = buildMeterPane.(paneTitles[0], paneBorderColors[0], "A"); // top-left real
paneArray[1] = buildMeterPane.(paneTitles[1], paneBorderColors[1], "B"); // top-right simulated
paneArray[2] = buildTextPane.(paneTitles[2], paneBorderColors[2]);
paneArray[3] = buildTextPane.(paneTitles[3], paneBorderColors[3]);
paneArray[4] = buildTextPane.(paneTitles[4], paneBorderColors[4]);
paneArray[5] = buildTextPane.(paneTitles[5], paneBorderColors[5]);

window.layout_(GridLayout.rows(
    [ paneArray[0], paneArray[1] ],
    [ paneArray[2], paneArray[3] ],
    [ paneArray[4], paneArray[5] ]
));
window.front;

// ---------- bring up real meter A (Ndef) and simulated meter B ----------
serverBootRoutine = Routine({
    var updateIntervalSeconds, phaseB, simulatedValueB, simulatedNoiseB;

    s.waitForBoot({
        var defaultNumChannels;
        defaultNumChannels = 2;

        s.initTree;
        s.defaultGroup.freeAll;

        amplitudeBusA = Bus.control(s, 1);

        Ndef(\meterSourceA, {
            var leftFrequency, rightFrequency, stereoSignal, monoSignal, amplitudeValue, meterBusIndex;
            leftFrequency  = 220 + LFTri.kr(0.10).range(-20,  20);
            rightFrequency = 330 + LFTri.kr(0.13).range(-30,  30);
            stereoSignal   = [Saw.ar(leftFrequency), Saw.ar(rightFrequency)] * 0.07;
            monoSignal     = stereoSignal.sum * 0.5;
            amplitudeValue = Amplitude.ar(monoSignal, 0.01, 0.30).clip(0.0, 1.5);
            meterBusIndex  = \meterBus.kr(0);
            Out.kr(meterBusIndex, amplitudeValue);
            (stereoSignal.tanh * 0.9)
        });

        Ndef(\meterSourceA).set(\meterBus, amplitudeBusA.index);
        Ndef(\meterSourceA).play;
    });

    updateIntervalSeconds = 0.05;
    phaseB = 0.0;

    meterRoutine = Routine({
        loop {
            amplitudeBusA.get({ |busValueA|
                var mappedValueA;
                mappedValueA = busValueA.clip(0.0, 1.0);
                { if(meterViewA.notNil, { meterViewA.value_(mappedValueA) }) }.defer;
            });

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
