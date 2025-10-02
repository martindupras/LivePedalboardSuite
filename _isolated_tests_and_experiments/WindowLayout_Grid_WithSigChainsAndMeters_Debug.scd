// WindowLayout_Grid_WithSigChainsAndMeters_Debug.scd
// v1.6 - no non-local returns (no ^); robust SendPeakRMS parser; console prints restored
// MD 20250930

/* Purpose
   - Fix “no console output” by eliminating ^ non-local returns inside parseRMS.
   - Robustly parse SendPeakRMS with/without address and with/without numCh.
   - Keep your GUI + chains intact and meters moving.

   Style
   - var-first declarations in every block
   - lowercase names, descriptive
   - AppClock defer for GUI updates
   - no non-local returns
*/

(

var window, makePane, paneColor;
var topLeftText, topLeftMeter, topRightText, topRightMeter;

var oscNameA, oscNameB, oscConsoleA, oscConsoleB;
var chainA, chainB, ensureStereo, rebuildChain, chainToString;
var setSourceA, setSourceB;

var parseRMS;

var countA = 0, countB = 0, firstDumpA = true, firstDumpB = true;

("test").postln;

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
            topLeftMeter = LevelIndicator().fixedWidth_(30).warning_(0.50).critical_(0.80)
        ), "Top Left Pane"),
        makePane.(HLayout(
            topRightText  = TextView().editable_(false),
            topRightMeter = LevelIndicator().fixedWidth_(30).warning_(0.50).critical_(0.80)
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
    Ndef(\srcA, { PinkNoise.ar(0.10 ! 2) });
    Ndef(\srcB, { SinOsc.ar([300, 301], mul: 0.20) });
    Ndef(\srcC, { LFSaw.ar([167, 171]).tanh * 0.18 });

    // --- RECEIVERS (sinks) ---
    // Keep distinct replyIDs (A=1, B=2) to match your earlier dumps.
    Ndef(\outA, {
        var sig;
        sig = \in.ar(2);
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsA', 1);
        sig
    });

    Ndef(\outB, {
        var sig;
        sig = \in.ar(2);
        SendPeakRMS.kr(sig, 20, 3, '/peakrmsB', 2);
        sig
    });

    // --- Chain helpers ---
    ensureStereo = { |key|
        var bus;
        bus = Ndef(key).bus;
        if(bus.isNil or: { bus.rate != \audio } or: { bus.numChannels != 2 }) {
            Ndef(key).ar(2);  // pre-arm as stereo
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
    chainA = [\outA, \srcA];
    chainB = [\outB, \srcB];
    rebuildChain.(chainA);
    rebuildChain.(chainB);

    // --- (Re)bind OSC responders (avoid duplicates on re-eval) ---
    { OSCdef(oscNameA).free; OSCdef(oscNameB).free; OSCdef(oscConsoleA).free; OSCdef(oscConsoleB).free; }.value;

    // Robust RMS parser (no ^ anywhere):
    // Supports:
    //   A) [address?, nodeID, replyID, numCh, peak1, rms1, peak2, rms2, ...]
    //   B) [address?, nodeID, replyID,        peak1, rms1, peak2, rms2, ...]
    parseRMS = { |msg|
        var ret, hasAddr, base, msgSize, maybeNumCh, dataStart, pairs, sum, k, rmsIndex;

        ret = 0.0;
        if(msg.notNil) {
            msgSize = msg.size;
            hasAddr = (msgSize > 0) && { msg[0].isString };
            base = hasAddr.binaryValue;

            // Decide layout by looking at slot base+2 and overall payload length
            if(msgSize >= (base + 4)) {
                maybeNumCh = msg[base + 2];
                if(maybeNumCh.isNumber and: { (msgSize - (base + 3)) >= (maybeNumCh.asInteger * 2) }) {
                    dataStart = base + 3;
                    pairs = maybeNumCh.asInteger.max(1);
                }{
                    dataStart = base + 2;
                    pairs = ((msgSize - dataStart) / 2).floor.max(0);
                };
            }{
                dataStart = base + 2;
                pairs = ((msgSize - dataStart) / 2).floor.max(0);
            };

            if(pairs > 0) {
                sum = 0.0;
                k = 0;
                while({ k < pairs }, {
                    rmsIndex = dataStart + (k * 2) + 1;  // second of each (peak,rms)
                    if(rmsIndex < msgSize) {
                        sum = sum + msg[rmsIndex].asFloat;
                    };
                    k = k + 1;
                });
                if(pairs > 0) {
                    ret = (sum / pairs).clip(0.0, 1.0);
                };
            };
        };
        ret
    };

    // GUI meter updaters (20 Hz)
    OSCdef(oscNameA, { |msg| { topLeftMeter.value_(parseRMS.(msg))  }.defer; }, '/peakrmsA');
    OSCdef(oscNameB, { |msg| { topRightMeter.value_(parseRMS.(msg)) }.defer; }, '/peakrmsB');

    // Console printers (~1 Hz by decimation) + first-message dump
    OSCdef(oscConsoleA, { |msg|
        var v;
        if(firstDumpA) { "A first msg: %".format(msg).postln; firstDumpA = false; };
        countA = countA + 1;
        if(countA >= 20) {
            v = parseRMS.(msg);
            v = v.max(1e-6);
            ("A RMS: " ++ (v.ampDb.round(0.1)) ++ " dB  (" ++ v.round(0.003) ++ ")").postln;
            countA = 0;
        };
    }, '/peakrmsA');

    OSCdef(oscConsoleB, { |msg|
        var v;
        if(firstDumpB) { "B first msg: %".format(msg).postln; firstDumpB = false; };
        countB = countB + 1;
        if(countB >= 20) {
            v = parseRMS.(msg);
            v = v.max(1e-6);
            ("B RMS: " ++ (v.ampDb.round(0.1)) ++ " dB  (" ++ v.round(0.003) ++ ")").postln;
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
