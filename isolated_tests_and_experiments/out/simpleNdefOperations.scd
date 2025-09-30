// sanityTestsWithNdefs.scd
// v.0.2
// MD 20250930

(
// vars
var win, meterA, meterB;

// create display window:
win = Window("RMS Meters", Rect(100, 100, 300, 400)).front;
win.layout = HLayout(  // Horizontal layout for left/right panes
    VLayout(  // Left pane
        StaticText().string_("Sink A").align_(\center),
        meterA = LevelIndicator()
            .numTicks_(10)
            .style_(\led)
            .minHeight_(200)    // Control meter height
            .minWidth_(50)      // Control meter width
    ).margins_(5).spacing_(5),   // Outline: margins create visible border

    VLayout(  // Right pane
        StaticText().string_("Sink B").align_(\center),
        meterB = LevelIndicator()
            .numTicks_(10)
            .style_(\led)
            .minHeight_(200)
            .minWidth_(50)
    ).margins_(5).spacing_(5)
);

// create Ndef sources:
Ndef(\srcA, {PinkNoise.ar(0.1 ! 2)});
Ndef(\srcB, {SinOsc.ar([300,301], mul:0.2)});
Ndef(\srcC, {SinOsc.ar([250,301], mul:0.2)});

// Sink Ndefs with SendPeakRMS monitoring
Ndef(\sinkA, {
    var sig = Ndef(\srcA).ar;
    // SendPeakRMS sends both peak and RMS values
    // Arguments: signal, replyRate (Hz), peakLag, OSC address, replyID
    SendPeakRMS.kr(sig, 20, 3, '/peakrmsA', 1);  // 20Hz for meters
    sig;
});

Ndef(\sinkB, {
    var sig = Ndef(\srcB).ar;
    SendPeakRMS.kr(sig, 20, 3, '/peakrmsB', 2);
    sig;
});

// Fast OSCdef responders for meters (20Hz updates)
OSCdef(\rmsAMeter, {|msg|
    // msg[3] = replyID, msg[4] = numChannels, msg[5] = peak, msg[6] = RMS
    {meterA.value = msg[6]}.defer;  // Use RMS value
}, '/peakrmsA');

OSCdef(\rmsBMeter, {|msg|
    {meterB.value = msg[6]}.defer;
}, '/peakrmsB');

// Slow responders for console printing (1Hz)
// We'll use a simple counter to print every Nth update
~printCounterA = 0;
~printCounterB = 0;

OSCdef(\rmsAConsole, {|msg|
    ~printCounterA = ~printCounterA + 1;
    if(~printCounterA >= 20, {  // Print every 20th message (20Hz / 20 = 1Hz)
        "sinkA RMS: % dB".format((msg[6].ampdb).round(0.1)).postln;
        ~printCounterA = 0;
    });
}, '/peakrmsA');

OSCdef(\rmsBConsole, {|msg|
    ~printCounterB = ~printCounterB + 1;
    if(~printCounterB >= 20, {
        "sinkB RMS: % dB".format((msg[6].ampdb).round(0.1)).postln;
        ~printCounterB = 0;
    });
}, '/peakrmsB');

// Cleanup when window closes
win.onClose = {
    OSCdef(\rmsAMeter).free;
    OSCdef(\rmsBMeter).free;
    OSCdef(\rmsAConsole).free;
    OSCdef(\rmsBConsole).free;
};

// Play the sinks
Ndef(\sinkA).play;
Ndef(\sinkB).play;
)