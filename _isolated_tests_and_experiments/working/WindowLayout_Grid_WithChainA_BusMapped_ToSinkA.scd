// WindowLayout_Grid_WithChainA_BusMapped_ToSinkA.scd
// v1.0 - Dark-green grid + srcA/B/C + chainA (bus-mapped) -> sinkA + live meter
// MD 20250930

/*
// After evaluating the block:
~routeChainA.(\srcB);   // Left label -> "srcB → sinkA"; left meter follows srcB
~routeChainA.(\srcC);
~routeChainA.(\srcA);
*/

/*
Purpose:
  - Same minimal dark-green window.
  - Sources: srcA, srcB, srcC (stereo).
  - chainA reads from a bus chosen via set(\in, busIndex) and can host processing.
  - sinkA reads chainA, meters with SendPeakRMS, and plays.
  - Left pane shows "srcX → sinkA". Use ~routeChainA.(\srcB) to switch.

*/

(
var window, makePane, paneColor;
var topLeftText, topLeftMeter, topRightText, topRightMeter;
var oscNameA, chainLabelFor;

// ---------- GUI ----------

Window.allWindows.do({ |w| if(w.name == "Layout Test", { w.close }) });

window = Window("Layout Test", Rect(100, 100, 800, 600))
    .background_(Color.white)
    .front;

paneColor = Color(0.0, 0.35, 0.0);
chainLabelFor = { |srcSym, sinkSym| srcSym.asString ++ " → " ++ sinkSym.asString };

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

window.layout = GridLayout.rows(
    [
        // LEFT: chain text + meter (sinkA)
        makePane.(HLayout(
            topLeftText  = TextView(),
            topLeftMeter = LevelIndicator().fixedWidth_(30)
        ), "Top Left Pane"),

        // RIGHT: free notes or future second sink
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

// ---------- Audio graph: src -> chainA (bus) -> sinkA (metered) ----------

oscNameA = \rmsA_toGUI;

Server.default.waitForBoot({
    // Sources (stereo)
    Ndef(\srcA, { PinkNoise.ar(0.10 ! 2) });
    Ndef(\srcB, { SinOsc.ar([300, 301], mul: 0.20) });
    Ndef(\srcC, { LFSaw.ar([167, 171]).tanh * 0.18 });

    // chainA: read audio from a BUS chosen via the named control \in
    // IMPORTANT: use In.ar(\in.kr(0), 2)  (NOT \in.ar(2))
    Ndef(\chainA, {
        var inBus = \in.kr(0);          // control for input bus index
        var sig   = In.ar(inBus, 2);    // read 2 channels from that bus
        // Optional processing on sig goes here (e.g., sig = sig * 0.9;)
        sig
    });

    // sinkA: read the chain, meter to GUI, and play
    Ndef(\sinkA, {
        var sig = Ndef(\chainA).ar;       // *** actually read chainA audio ***
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsA', 1);
        sig
    });

    // Start sink
    Ndef(\sinkA).play;

    // Safe (re)bind for OSC responder
    { OSCdef(oscNameA).free }.value;
    OSCdef(oscNameA, { |msg| { topLeftMeter.value_(msg[6]) }.defer; }, '/peakrmsA');

    // Initial routing: map chainA's input bus to srcA's bus
    Ndef(\chainA).set(\in, Ndef(\srcA).bus.index);

    // GUI labels / hints
    { topLeftText.string_(chainLabelFor.(\srcA, \sinkA)) }.defer;
    { topRightText.string_("Use ~routeChainA.(\\srcB) or (\\srcC) to reroute chainA.") }.defer;
});

// ---------- Helper: re-route chainA by bus mapping ----------

~routeChainA = { |srcSym|
    var s = srcSym.asSymbol;
    var b = Ndef(s).bus.index;              // source's audio bus index
    Ndef(\chainA).set(\in, b);              // re-route
    { topLeftText.string_(chainLabelFor.(s, \sinkA)) }.defer;
};

// ---------- Cleanup ----------

window.onClose = {
    Ndef(\sinkA).stop;
    OSCdef(oscNameA).free;
};

window  // -> a Window
)


