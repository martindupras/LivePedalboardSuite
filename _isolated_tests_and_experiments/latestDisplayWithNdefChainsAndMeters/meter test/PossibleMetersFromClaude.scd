// PossibleLevelMeter.scd
// v 0.5
// MD 20251001

/* not terrible, and reasonably accurate (but seems to indicate actual amplitude from RMS readings. I could live that.)

s.waitForBoot({
    var win, meterView, levelIndicator, ampButtons, ampValues, currentAmp;
    var dbTicks, responder;

    // Amplitude values in linear scale
    ampValues = [
        1.0,      // 0 dBFS
        0.5,      // -6 dBFS (approximately)
        0.25,     // -12 dBFS
        0.125,    // -18 dBFS
        0.1,      // -20 dBFS
        0.001,    // -60 dBFS
        0.0       // -128 dBFS (silence)
    ];

    currentAmp = 0; // Index for current amplitude

    // Create the Ndef with sawtooth wave and peak monitoring
    Ndef(\saw, {
        var sig = Saw.ar(100) * \amp.kr(0);
        sig = sig ! 2; // Stereo
        SendPeakRMS.kr(sig, 20, 3, '/meter'); // Send peak values
        sig;
    });

    Ndef(\saw).play;

    // Create GUI window
    win = Window("Sawtooth Wave - dB Meter", Rect(100, 100, 400, 500))
        .front
        .onClose_({
            Ndef(\saw).clear;
            responder.free;
        });

    win.view.decorator = FlowLayout(win.view.bounds, 10@10, 10@10);

    // Title
    StaticText(win, 380@30)
        .string_("100 Hz Sawtooth Wave Generator")
        .align_(\center)
        .font_(Font.default.size_(16));

    win.view.decorator.nextLine;

    // Amplitude selection buttons
    StaticText(win, 380@20)
        .string_("Select Amplitude:")
        .font_(Font.default.size_(12));

    win.view.decorator.nextLine;

    ampButtons = [
        "0 dBFS",
        "-6 dBFS",
        "-12 dBFS",
        "-18 dBFS",
        "-20 dBFS",
        "-60 dBFS",
        "-128 dBFS (Off)"
    ].collect({ |label, i|
        Button(win, 120@30)
            .states_([[label, Color.black, Color.gray(0.8)]])
            .action_({
                currentAmp = i;
                Ndef(\saw).set(\amp, ampValues[i]);
                ("Amplitude set to " ++ label).postln;
            });
    });

    win.view.decorator.nextLine;
    win.view.decorator.nextLine;

    // Meter section
    StaticText(win, 380@20)
        .string_("Level Meter:")
        .font_(Font.default.size_(12));

    win.view.decorator.nextLine;

    // Create a composite view for meter with labels
    meterView = CompositeView(win, 380@300)
        .background_(Color.gray(0.2));

    // Level indicator (vertical meter) - position first
    levelIndicator = LevelIndicator(meterView, Rect(80, 20, 80, 260))
        .warning_(0.7)
        .critical_(0.9)
        .numSteps_(60)
        .numTicks_(11)
        .numMajorTicks_(11)
        .drawsPeak_(true)
        .style_(\led);

    // dB tick marks - adjusted to match LevelIndicator's linear amplitude scale
    // LevelIndicator displays LINEAR amplitude (0 to 1), not dB
    // So we need to convert: amplitude = 10^(dB/20)
    dbTicks = [0, -6, -12, -18, -24, -30, -36, -42, -48, -54, -60];

    // Draw tick marks and labels immediately next to the meter
    dbTicks.do({ |db, i|
        var linearAmp = 10.pow(db / 20); // Convert dB to linear amplitude
        var yPos = 20 + (260 * (1 - linearAmp)); // Map to meter position (top is amp=1.0, bottom is amp=0)

        // Tick mark line (right next to meter)
        StaticText(meterView, Rect(165, yPos - 1, 15, 2))
            .background_(Color.white);

        // dB label
        StaticText(meterView, Rect(185, yPos - 10, 50, 20))
            .string_(db.asString ++ " dB")
            .font_(Font.default.size_(10))
            .stringColor_(Color.white);

        // Highlight 0 dBFS
        if (db == 0, {
            StaticText(meterView, Rect(240, yPos - 10, 50, 20))
                .string_("← 0 dBFS")
                .font_(Font.default.size_(10).boldVariant)
                .stringColor_(Color.red);
        });
    });

    // Channel labels
    StaticText(meterView, Rect(85, 285, 30, 15))
        .string_("L")
        .align_(\center)
        .stringColor_(Color.white);

    StaticText(meterView, Rect(125, 285, 30, 15))
        .string_("R")
        .align_(\center)
        .stringColor_(Color.white);

    // OSC responder to receive peak values
    responder = OSCFunc({ |msg|
        var peakL, peakR;
        // msg format: ['/meter', nodeID, replyID, peakL, peakR, rmsL, rmsR]
        peakL = msg[3];
        peakR = msg[4];

        // Update meter on AppClock
        {
            levelIndicator.value = peakL.max(peakR);
            levelIndicator.peakLevel = peakL.max(peakR);
        }.defer;
    }, '/meter');

    "Sawtooth wave generator ready. Select an amplitude to begin.".postln;
});