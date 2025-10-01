// WindowLayout_Grid_WithSigChainsAndMeters.scd
// v1.2 - Aligns with sigChainOperations: <<> wiring + \in.ar(2) sinks; meters A & B
// MD 20250930

/*
Purpose:
  - Same dark-green window (3x2 grid).
  - Sources: srcA/srcB/srcC (stereo).
  - Chains: chainA=[outA,...,src?], chainB=[outB,...,src?], wired by Ndef(left) <<> Ndef(right).
  - Sinks: outA/outB read \in.ar(2), meter with SendPeakRMS to GUI.
  - Left pane meters sinkA; right pane meters sinkB; both panes display the full chain string.

Conventions (from sigChainOperations v0.2.1):
  - Receivers that consume audio MUST declare \in.ar(2).
  - Wiring uses Ndef(left) <<> Ndef(right) (left receives right at \in).
  - (Optional) pre-arm proxies to stereo audio buses before wiring.  [See file notes]
*/

(
var window, makePane, paneColor;
var topLeftText, topLeftMeter, topRightText, topRightMeter;
var oscNameA, oscNameB;

// --- chain data + functions (mirroring your sigChain style) ---
var chainA, chainB;
var ensureStereo, rebuildChain, chainToString;
var setSourceA, setSourceB;

// ---------- GUI ----------
Window.allWindows.do({ |w| if(w.name == "Layout Test", { w.close }) });

window = Window("Layout Test", Rect(100, 100, 800, 600))
    .background_(Color.white)
    .front;

paneColor = Color(0.0, 0.35, 0.0);

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
        makePane.(HLayout(
            topLeftText  = TextView(),
            topLeftMeter = LevelIndicator().fixedWidth_(30)
        ), "Top Left Pane"),

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

// ---------- Audio graph + chains ----------
oscNameA = \rmsA_toGUI;
oscNameB = \rmsB_toGUI;

Server.default.waitForBoot({
    // --- SOURCES (stereo) ---
    Ndef(\srcA, { PinkNoise.ar(0.10 ! 2) });
    Ndef(\srcB, { SinOsc.ar([300, 301], mul: 0.20) });
    Ndef(\srcC, { LFSaw.ar([167, 171]).tanh * 0.18 });

    // --- RECEIVERS (MUST declare \in.ar(2)) ---
    // outA: sink for chainA (also meters -> /peakrmsA)
    Ndef(\outA, {
        var sig = \in.ar(2);
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsA', 1);  // id=1
        sig
    });

    // outB: sink for chainB (also meters -> /peakrmsB)
    Ndef(\outB, {
        var sig = \in.ar(2);
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsB', 2);  // id=2
        sig
    });

    // --- OPTIONAL PROCESSORS (declared here to be ready if you insert them) ---
    // Ndef(\p1, { var inSig = \in.ar(2) * 0.8; inSig });
    // Ndef(\p2, { var inSig = \in.ar(2).tanh * 0.7; inSig });

    // --- CHAIN HELPERS (aligned with sigChainOperations) ---
    ensureStereo = { |key|
        var bus = Ndef(key).bus;
        if(bus.isNil or: { bus.rate != \audio