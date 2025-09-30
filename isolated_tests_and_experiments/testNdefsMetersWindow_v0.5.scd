// WindowLayout_Grid_WithNdefsMeters.scd
// v1.0 - Minimal dark-green grid + Ndefs + live meters (sinkA/B) + chain labels
// MD 20250930

/*
Purpose:
  - Create the same window as your minimal dark-green grid.
  - Define Ndefs (srcA, srcB, sinks with SendPeakRMS).
  - Drive the left/right meters from sinkA/sinkB RMS.
  - Show chain text in the top-left / top-right panes.

Style:
  - var-first, descriptive names, no non-local returns, no server.sync.
  - Uses OSCdef responders and .defer for GUI safety.
  - Returns '-> a Window'.
*/

(
var window, makePane, paneColor;
var topLeftText, topLeftMeter, topRightText, topRightMeter;
var chainAString, chainBString;
var oscNameA, oscNameB;

// close any existing window with the same name
Window.allWindows.do({ |w| if(w.name == "Layout Test", { w.close }) });

// window
window = Window("Layout Test", Rect(100, 100, 800, 600))
    .background_(Color.white)
    .front;

// single colour (dark green)
paneColor = Color(0.0, 0.35, 0.0);

// simple chain labels (edit any time)
chainAString = "srcA → sinkA";
chainBString = "srcB → sinkB";

// OSC address (and names) for meters
oscNameA = \rmsA_toGUI;
oscNameB = \rmsB_toGUI;

// helper: pane with coloured label + thin outline (local coords)
makePane = { |content, label|
    var labelView, inner, pane;
    labelView = StaticText()
        .string_(label)
        .align_(\center)
        .stringColor_(Color.white)
        .background_(paneColor);
    inner = VLayout(labelView, content);
    pane = UserView().layout_(inner);
    pane.drawFunc_({ |v|
        var inset = 0.5;
        Pen.use {
            Pen.color = paneColor;
            Pen.width = 1;
            Pen.addRect(Rect(inset, inset, v.bounds.width - (2 * inset), v.bounds.height - (2 * inset)));
            Pen.stroke;
        };
    });
    pane
};

// grid (3 rows × 2 columns) with shared column boundaries
window.layout = GridLayout.rows(
    [
        // LEFT: TextView + LevelIndicator (we keep references)
        makePane.(HLayout(
            topLeftText  = TextView(),
            topLeftMeter = LevelIndicator().fixedWidth_(30)
        ), "Top Left Pane"),

        // RIGHT: TextView + LevelIndicator (keep references)
        makePane.(HLayout(
            topRightText  = TextView(),
            topRightMeter = LevelIndicator().fixedWidth_(30)
        ), "Top Right Pane")
    ],
    [
        makePane.(VLayout(StaticText().align_(\center), TextView()), "System State"),
        makePane.(VLayout(StaticText().align_(\center), TextView()), "Diagnostic Messages")
    ],
    [
        makePane.(VLayout(StaticText().align_(\center), TextView()), "Choices"),
        makePane.(VLayout(StaticText().align_(\center), TextView()), "Receiving Commands")
    ]
);

// set chain text in top panes
topLeftText.string_(chainAString);
topRightText.string_(chainBString);

// ---------- audio graph + metering ----------
Server.default.waitForBoot({
    // sources
    Ndef(\srcA, { PinkNoise.ar(0.10 ! 2) });                  // stereo pink at modest level
    Ndef(\srcB, { SinOsc.ar([300, 301], mul: 0.20) });        // stereo close tones
    Ndef(\srcC, { SinOsc.ar([167, 171], mul: 0.20) });        // stereo close tones

/*    // sinks with SendPeakRMS -> GUI (20 Hz is light but responsive)
    Ndef(\sinkA, {
        var sig = Ndef(\srcA).ar;
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsA', 1);
        sig
    });*/

// Create them 2ch before we do anything else
	Ndef(\sinkA, {Silent.ar(2)});
    Ndef(\sinkB, {Silent.ar(2)});


	    Ndef(\sinkA, {
        var sig = Ndef(\srcB).ar;
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsA', 2);
        sig
    });

    Ndef(\sinkB, {
        var sig = Ndef(\srcB).ar;
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsB', 2);
        sig
    });

    // play sinks
    Ndef(\sinkA).play;
    Ndef(\sinkB).play;

    // meter responders (RMS at msg[6]); defer to GUI thread
    OSCdef(oscNameA, { |msg| { topLeftMeter.value_(msg[6]) }.defer;  }, '/peakrmsA');
    OSCdef(oscNameB, { |msg| { topRightMeter.value_(msg[6]) }.defer; }, '/peakrmsB');
});

// cleanup when window closes (stop sinks + free responders; leave sources defined)
window.onClose = {
    Ndef(\sinkA).stop;
    Ndef(\sinkB).stop;
    OSCdef(oscNameA).free;
    OSCdef(oscNameB).free;
};

window  // -> a Window
)

/*(Ndef(\srcA).bus).postln;
(Ndef(\srcB).bus).postln;
(Ndef(\srcC).bus).postln;
(Ndef(\sinkA).bus).postln;
(Ndef(\sinkB).bus).postln;

Ndef(\sinkA).play;
Ndef(\sinkA).stop;

Ndef(\sinkB).play;
Ndef(\sinkB).stop;

Ndef(\sinkB) <<> Ndef(\srcA);
Ndef(\sinkB) <<> Ndef(\srcB);
Ndef(\sinkA) <<> Ndef(\srcC);

Ndef(\sinkA) <<> Ndef(\srcA);
Ndef(\sinkA) <<> Ndef(\srcB);
Ndef(\sinkA) <<> Ndef(\srcC);*/