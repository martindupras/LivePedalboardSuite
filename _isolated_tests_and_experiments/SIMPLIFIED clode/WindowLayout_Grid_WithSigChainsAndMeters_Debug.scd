// WindowLayout_Grid_WithSigChainsAndMeters_Debug.scd
// v1.8 - minimal meter fix (last RMS value), 'ampdb' console, no non-local returns (^)
// MD 20250930

/* Purpose
   - Restore moving meters using a simple, robust extractor: take the last numeric (RMS) value in the OSC message.
   - Fix console level print by using 'ampdb' (lowercase).
   - Keep everything else unchanged: your chain helpers, GUI layout, and OSC bindings.
   - No non-local returns anywhere.

*/

(
var window, makePane, paneColor;
var topLeftText, topLeftMeter, topRightText, topRightMeter;

var oscNameA, oscNameB, oscConsoleA, oscConsoleB;
var chainA, chainB, ensureStereo, rebuildChain, chainToString;
var setSourceA, setSourceB;

var valueFromMsg;

var countA = 0, countB = 0, firstDumpA = true, firstDumpB = true;

// ---------- GUI ----------
Window.allWindows.do({ |w| if(w.name == "Layout Test", { w.close }) });

window = Window("Layout Test", Rect(100, 100, 800, 600))
    .background_(Color.white)
    .front;

paneColor = Color(0.0, 0.35, 0.0);

makePane = { |content, label|
    var labelView, inner, pane, inset;
    labelView = StaticText()
        .string_(label)
        .align_(\center)
        .stringColor_(Color.white)
        .background_(paneColor);
    inner = VLayout(labelView, content);
    pane = UserView().layout_(inner);
    pane.drawFunc_({ |v|
        inset = 0.5;
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
            topLeftText  = TextView().editable_(false),
            topLeftMeter = LevelIndicator().fixedWidth_(30)
        ), "Top Left Pane"),
        makePane.(HLayout(
            topRightText  = TextView().editable_(false),
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

// ---------- Audio graph + sigChains ----------
oscNameA     = \rmsA_toGUI;
oscNameB     = \rmsB_toGUI;
oscConsoleA  = \rmsA_console;
oscConsoleB  = \rmsB_console;

Server.default.waitForBoot({
    // --- SOURCES (stereo) ---
	Ndef(\srcZ, { Silent.ar(numChannels:1) });
    Ndef(\srcA, { PinkNoise.ar(0.10 ! 2) });
    Ndef(\srcB, { SinOsc.ar([300, 301], mul: 0.20) });
    Ndef(\srcC, { LFSaw.ar([167, 171]).tanh * 0.18 });

    // --- RECEIVERS (sinks) MUST declare \in.ar(2); they also meter to GUI ---
    // Keep replyIDs A=1, B=2 to match earlier dumps.
    Ndef(\outA, {
        var sig;
        sig = \in.ar(2);
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsA', 1);

		/*
		//TEST TextVU:
		// it works but is just difficult to read between the rest of the console messages. Nice though.
		TextVU.ar(2, sig, "sinkA"); // 2 = trig 2Hz
        */

		sig
    });

    Ndef(\outB, {
        var sig;
        sig = \in.ar(2);
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsB', 2);
        sig
    });

    // --- Chain helpers (mirrors your sigChainOperations style) ---
    ensureStereo = { |key|
        var bus;
        bus = Ndef(key).bus;
        if(bus.isNil or: { bus.rate != \audio } or: { bus.numChannels != 2 }) {
            Ndef(key).ar(2);  // pre-arm as stereo audio before wiring
        };
    };

    chainToString = { |anArray|
        var forward;
        forward = anArray.copy.reverse; // [source, ..., sink]
        forward.collect(_.asString).join(" → ")
    };

    rebuildChain = { |anArray|
        var i;
        i = 0;
        if(anArray.size < 2) {
            "need at least [sink, source]".postln;
        }{
            anArray.do(ensureStereo);
            i = 0;
            while({ i < (anArray.size - 1) }, {
                Ndef(anArray[i]) <<> Ndef(anArray[i + 1]);  // left receives right at \in
                i = i + 1;
            });
            Ndef(anArray[0]).play(numChannels: 2);  // play the sink
        };
    };

    // --- INITIAL CHAINS ---
    chainA = [\outA, \srcA];   // chainA: sink ... source
    chainB = [\outB, \srcB];   // chainB
    rebuildChain.(chainA);
    rebuildChain.(chainB);

    // --- (Re)bind OSC responders (avoid duplicates on re-eval) ---
    { OSCdef(oscNameA).free; OSCdef(oscNameB).free; OSCdef(oscConsoleA).free; OSCdef(oscConsoleB).free; }.value;

    // --- Minimal, robust extractor for meter value: take the last number (typically final RMS) ---
    valueFromMsg = { |msg|
        var v, sz;
        v = 0.0;
        if(msg.notNil) {
            sz = msg.size;
            if(sz >= 4) {  // enough to have at least one (peak,rms) after node+reply
                v = msg[sz - 1].asFloat;  // last element; usually an RMS
            };
        };
        v.clip(0.0, 1.0) // MAYBE ADD if v< 0.0 or v >1.0  warning to console
    };

    // GUI meter updaters (20 Hz)
    OSCdef(oscNameA, { |msg| { topLeftMeter.value_(valueFromMsg.(msg))  }.defer; }, '/peakrmsA');
    OSCdef(oscNameB, { |msg| { topRightMeter.value_(valueFromMsg.(msg)) }.defer; }, '/peakrmsB');

    // Console printers (~1 Hz by decimation) + first-message dump (uses ampdb, lowercase)
    OSCdef(oscConsoleA, { |msg|
        var v;
        if(firstDumpA) { "A first msg: %".format(msg).postln; firstDumpA = false; };
        countA = countA + 1;
        if(countA >= 20) {
            v = valueFromMsg.(msg).max(1e-6);
            ("A level: " ++ (v.ampdb.round(0.1)) ++ " dB  (" ++ v.round(0.003) ++ ")").postln;
            countA = 0;
        };
    }, '/peakrmsA');

    OSCdef(oscConsoleB, { |msg|
        var v;
        if(firstDumpB) { "B first msg: %".format(msg).postln; firstDumpB = false; };
        countB = countB + 1;
        if(countB >= 20) {
            v = valueFromMsg.(msg).max(1e-6);
            ("B level: " ++ (v.ampdb.round(0.1)) ++ " dB  (" ++ v.round(0.003) ++ ")").postln;
            countB = 0;
        };
    }, '/peakrmsB');

    // Show full chain strings in the GUI
    {
        topLeftText.string_(chainToString.(chainA));
        topRightText.string_(chainToString.(chainB));
    }.defer;
});

// ---------- Convenience: change ONLY the source at the tail of each chain ----------
setSourceA = { |srcSym|
    var newSym;
    newSym = srcSym.asSymbol;
    chainA[chainA.size - 1] = newSym;
    rebuildChain.(chainA);
    { topLeftText.string_(chainToString.(chainA)) }.defer;
};

setSourceB = { |srcSym|
    var newSym;
    newSym = srcSym.asSymbol;
    chainB[chainB.size - 1] = newSym;
    rebuildChain.(chainB);
    { topRightText.string_(chainToString.(chainB)) }.defer;
};

~setSourceA = setSourceA;
~setSourceB = setSourceB;

// ---------- Cleanup ----------
window.onClose = {
    Ndef(\outA).stop;
    Ndef(\outB).stop;
    OSCdef(oscNameA).free;
    OSCdef(oscNameB).free;
    OSCdef(oscConsoleA).free;
    OSCdef(oscConsoleB).free;
};

window  // -> a Window
)
