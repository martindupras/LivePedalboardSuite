/////////////////////////////////////////////////////////////
// SixPanes_GridLayout_TwoMeters_SteppedDB_Sound.scd
// v0.7.0
// MD 2025-09-25 15:24
//
// Purpose / Style:
// - GUI-only layout (GridLayout 3x2) with 2 meters in the top row.
// - Audible test source (Ndef) plays; its amplitude steps in 10 dB increments every second.
// - Meters A and B both follow the same stepped level.
// - Rules: var-first; descriptive lowercase names; no single-letter variables;
//   no non-local returns; no server.sync; known-good Qt syntax.
/////////////////////////////////////////////////////////////

(
var window, windowRect, windowBackgroundColor, paneFillColor;
var titleFont, bodyFont, meterLabelFont, paneBorderColors, paneTitles;
var buildTextPane, buildMeterPane, paneArray;

var meterViewA, meterViewB, meterStepRoutine, serverBringUpRoutine;
var dbStepValues, stepIntervalSeconds;
var amplitudeBusA;

// ---------- close prior MagicDisplayGUI windows ----------
Window.allWindows.do({ |existingWindow|
    var existingNameString;
    existingNameString = existingWindow.name.asString;
    if(existingNameString.beginsWith("MagicDisplayGUI"), { { existingWindow.close }.defer });
});

// ---------- window & styles ----------
windowRect = Rect(80, 60, 1200, 850);
window = Window("MagicDisplayGUI GridLayout + Stepped dB (with sound)", windowRect).alwaysOnTop_(true);
windowBackgroundColor = Color(0.08, 0.08, 0.09);
paneFillColor = Color(0.15, 0.15, 0.18);
window.view.background_(windowBackgroundColor);

titleFont      = Font("Helvetica-Bold", 16);
bodyFont       = Font("Menlo", 12);
meterLabelFont = Font("Helvetica-Bold", 13);

paneBorderColors = [Color.red, Color.green, Color.blue, Color.yellow, Color.magenta, Color.cyan];
paneTitles       = ["top-left","top-right","middle-left","middle-right","bottom-left","bottom-right"];

// ---------- stepped-meters parameters ----------
dbStepValues        = [-60, -50, -40, -30, -20, -10, 0];
stepIntervalSeconds = 1.0;

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
    bodyTextView  = StaticText().string_("Pane: " ++ paneTitleString ++ "\nLayout row with text.")
        .font_(bodyFont).stringColor_(Color(0.85, 0.9, 0.95));
    textColumnView = UserView().layout_(VLayout(UserView().minHeight_(6), titleTextView, UserView().minHeight_(4), bodyTextView, nil));
    paneView.layout_(VLayout(UserView().minHeight_(6), textColumnView, nil));
    paneView
};

buildMeterPane = { |paneTitleString, borderColor, labelTextString|
    var paneView, titleTextView, bodyTextView, textColumnView, meterLabelView, localMeterView, meterColumnView;
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
    bodyTextView  = StaticText().string_("Pane: " ++ paneTitleString ++ "\nMeter " ++ labelTextString ++ " steps in 10 dB increments.")
        .font_(bodyFont).stringColor_(Color(0.85, 0.9, 0.95));
    textColumnView = UserView().layout_(VLayout(UserView().minHeight_(6), titleTextView, UserView().minHeight_(4), bodyTextView, nil));
    meterLabelView = StaticText().string_(labelTextString).font_(meterLabelFont).stringColor_(Color.white).align_(\center);
    localMeterView = LevelIndicator().warning_(0.7).critical_(0.95).minSize_(Size(20, 180));
    if(labelTextString == "A", { meterViewA = localMeterView }, { meterViewB = localMeterView });
    meterColumnView = UserView().layout_(VLayout(UserView().minHeight_(4), meterLabelView, UserView().minHeight_(4), localMeterView, nil));
    paneView.layout_(HLayout(UserView().minWidth_(6), textColumnView, UserView().minWidth_(10), meterColumnView, UserView().minWidth_(6)));
    paneView
};

// ---------- assemble grid (top row has meters) ----------
paneArray = Array.newClear(6);
paneArray[0] = buildMeterPane.(paneTitles[0], paneBorderColors[0], "A");
paneArray[1] = buildMeterPane.(paneTitles[1], paneBorderColors[1], "B");
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

// ---------- AUDIO bring-up (audible Ndef + stepped amplitude) ----------
serverBringUpRoutine = Routine({
    s.waitForBoot({
        var defaultNumChannels, leftFrequency, rightFrequency;
        defaultNumChannels = 2;
        s.initTree; s.defaultGroup.freeAll;

        amplitudeBusA = Bus.control(s, 1);

        Ndef(\stepToneA, {
            var stereoSignal, monoSignal, amplitudeLinear, meterBusIndex;
            leftFrequency  = 220 + LFTri.kr(0.10).range(-20, 20);
            rightFrequency = 330 + LFTri.kr(0.13).range(-30, 30);
            stereoSignal   = (VarSaw.ar([leftFrequency, rightFrequency], 0.0, 0.35) * 0.5).tanh * 0.15;

            amplitudeLinear = Lag.kr(\amp.kr(0.05), 0.02); // smooth the steps
            stereoSignal    = stereoSignal * amplitudeLinear;

            monoSignal    = stereoSignal.sum * 0.5;
            meterBusIndex = \meterBus.kr(0);
            Out.kr(meterBusIndex, Amplitude.ar(monoSignal, 0.01, 0.30).clip(0.0, 1.5));

            stereoSignal
        });

        Ndef(\stepToneA).set(\meterBus, amplitudeBusA.index, \amp, 0.05);
        Ndef(\stepToneA).play;
    });
}).play(AppClock);

// ---------- STEP meters + audible amplitude ----------
meterStepRoutine = Routine({
    var stepIndex, stepCount, currentDb, currentLinear;
    stepIndex = 0;
    stepCount = dbStepValues.size;
    loop {
        currentDb     = dbStepValues.wrapAt(stepIndex);
        currentLinear = currentDb.dbamp.clip(0.0, 1.0);

        { if(meterViewA.notNil, { meterViewA.value_(currentLinear) });
          if(meterViewB.notNil, { meterViewB.value_(currentLinear) }); }.defer;

        Ndef(\stepToneA).set(\amp, currentLinear);

        stepIndex = stepIndex + 1;
        stepIntervalSeconds.wait;
    }
}).play(AppClock);

// ---------- cleanup ----------
window.onClose_({
    if(meterStepRoutine.notNil, { meterStepRoutine.stop });
    if(serverBringUpRoutine.notNil, { serverBringUpRoutine.stop });
    if(amplitudeBusA.notNil, { amplitudeBusA.free });
    if(Ndef.all.at(\stepToneA).notNil, { Ndef(\stepToneA).stop; Ndef(\stepToneA).clear; });
});
)
