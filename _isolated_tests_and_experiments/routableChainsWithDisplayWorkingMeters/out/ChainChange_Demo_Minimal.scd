// ChainChange_Demo_Minimal.scd
// v1.0 - change chain sources & processors interactively; meters + chain text
// MD 20250930

/* Purpose
   - Let you interactively change JITLib chains A and B:
     • setSourceA/B to swap sources
     • appendProcessorA/B to insert processors before the source
     • removeProcessorA/B to remove a processor by symbol
     • clearProcessorsA/B to keep only [sink, source]
     • setChainA/B to replace the whole chain explicitly
   - Show current chain strings in a small GUI + live meters (SendPeakRMS).
   - Keep re-eval safe: auto-close existing window, free/stop old defs.

   Style
   - var-first declarations everywhere
   - lowercase identifiers, descriptive names
   - Ndef(left) <<> Ndef(right); sinks/processors read \in.ar(2)
   - Server.default.waitForBoot, no server.sync, AppClock.defer for GUI touches
*/

(
var window, makePane, paneColor;
var topLeftText, topLeftMeter, topRightText, topRightMeter;

var oscNameA, oscNameB, oscConsoleA, oscConsoleB;
var chainA, chainB, ensureStereo, rebuildChain, chainToString, postChain, updateGui;
var setSourceA, setSourceB, appendProcessorA, appendProcessorB, removeProcessorA, removeProcessorB, clearProcessorsA, clearProcessorsB, setChainA, setChainB;

var valueFromMsg;

var countA = 0, countB = 0, firstDumpA = true, firstDumpB = true;

// ---------- GUI ----------
Window.allWindows.do({ |w| if(w.name == "Chain Change Demo", { w.close }) });

window = Window("Chain Change Demo", Rect(100, 100, 720, 300))
    .background_(Color.white)
    .front;

paneColor = Color(0.15, 0.35, 0.15);

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
        ), "Chain A"),
        makePane.(HLayout(
            topRightText  = TextView().editable_(false),
            topRightMeter = LevelIndicator().fixedWidth_(30)
        ), "Chain B")
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

    // --- PROCESSORS (stereo) ---
    Ndef(\p_gain, {
        var inSig, amp;
        inSig = \in.ar(2);
        amp = \amp.kr(0.8).clip(0.0, 2.0);
        inSig * amp
    });
    Ndef(\p_tanh, {
        var inSig, drive;
        inSig = \in.ar(2);
        drive = \drive.kr(1.0).clip(0.1, 5.0);
        (inSig * drive).tanh * 0.9
    });
    Ndef(\p_delay, {
        var inSig, delayTime, fb;
        inSig = \in.ar(2);
        delayTime = \time.kr(0.25).clip(0.0, 2.0);
        fb = \fb.kr(0.3).clip(0.0, 0.95);
        // simple stereo delay
        (DelayC.ar(inSig, 2.0, delayTime) * 0.7) + (inSig * (1.0 - fb))
    });

    // --- SINKS (stereo) send peak/rms to GUI ---
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
            Ndef(key).ar(2);  // ensure 2-ch audio
        };
    };

    chainToString = { |anArray|
        var forward;
        forward = anArray.copy.reverse; // [source, ..., sink]
        forward.collect(_.asString).join(" → ")
    };

    postChain = { |label, anArray|
        (label ++ ": " ++ chainToString.(anArray)).postln;
    };

    updateGui = {
        {
            topLeftText.string_(chainToString.(chainA));
            topRightText.string_(chainToString.(chainB));
        }.defer;
    };

    rebuildChain = { |anArray|
        var linkIndex, maxLink;
        if(anArray.size < 2) {
            "need at least [sink, source]".postln;
        }{
            anArray.do(ensureStereo);
            linkIndex = 0;
            maxLink = anArray.size - 1;
            while({ linkIndex < maxLink }, {
                Ndef(anArray[linkIndex]) <<> Ndef(anArray[linkIndex + 1]);
                linkIndex = linkIndex + 1;
            });
            Ndef(anArray[0]).play(numChannels: 2);
        };
    };

    // --- INITIAL CHAINS ---
    chainA = [\outA, \srcA];
    chainB = [\outB, \srcB];
    rebuildChain.(chainA);
    rebuildChain.(chainB);
    updateGui.();
    postChain.("ChainA", chainA);
    postChain.("ChainB", chainB);

    // --- OSC bindings (rebind safely on re-eval) ---
    { OSCdef(oscNameA).free; OSCdef(oscNameB).free; OSCdef(oscConsoleA).free; OSCdef(oscConsoleB).free; }.value;

    // Minimal value extractor for meters: last numeric (usually final RMS)
    valueFromMsg = { |msg|
        var v, sz;
        v = 0.0;
        if(msg.notNil) {
            sz = msg.size;
            if(sz >= 4) { v = msg[sz - 1].asFloat; };
        };
        v.clip(0.0, 1.0)
    };

    OSCdef(oscNameA, { |msg| { topLeftMeter.value_(valueFromMsg.(msg))  }.defer; }, '/peakrmsA');
    OSCdef(oscNameB, { |msg| { topRightMeter.value_(valueFromMsg.(msg)) }.defer; }, '/peakrmsB');

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

    // ---------- Chain edit API ----------
    setSourceA = { |srcSym|
        var newSym;
        newSym = srcSym.asSymbol;
        chainA[chainA.size - 1] = newSym;
        rebuildChain.(chainA);
        updateGui.();
        postChain.("ChainA", chainA);
    };

    setSourceB = { |srcSym|
        var newSym;
        newSym = srcSym.asSymbol;
        chainB[chainB.size - 1] = newSym;
        rebuildChain.(chainB);
        updateGui.();
        postChain.("ChainB", chainB);
    };

    appendProcessorA = { |procSym|
        var newSym, insertPos;
        newSym = procSym.asSymbol;
        insertPos = chainA.size - 1; // before source
        chainA = chainA.insert(insertPos, newSym);
        rebuildChain.(chainA);
        updateGui.();
        postChain.("ChainA", chainA);
    };

    appendProcessorB = { |procSym|
        var newSym, insertPos;
        newSym = procSym.asSymbol;
        insertPos = chainB.size - 1; // before source
        chainB = chainB.insert(insertPos, newSym);
        rebuildChain.(chainB);
        updateGui.();
        postChain.("ChainB", chainB);
    };

    removeProcessorA = { |procSym|
        var sym, newChain, keepIndex, lastIndex;
        sym = procSym.asSymbol;
        lastIndex = chainA.size - 1;
        newChain = Array.new;
        keepIndex = 0;
        while({ keepIndex < chainA.size }, {
            if((keepIndex == 0) or: { keepIndex == lastIndex } or: { chainA[keepIndex] != sym }) {
                newChain = newChain.add(chainA[keepIndex]);
            };
            keepIndex = keepIndex + 1;
        });
        chainA = newChain;
        rebuildChain.(chainA);
        updateGui.();
        postChain.("ChainA", chainA);
    };

    removeProcessorB = { |procSym|
        var sym, newChain, keepIndex, lastIndex;
        sym = procSym.asSymbol;
        lastIndex = chainB.size - 1;
        newChain = Array.new;
        keepIndex = 0;
        while({ keepIndex < chainB.size }, {
            if((keepIndex == 0) or: { keepIndex == lastIndex } or: { chainB[keepIndex] != sym }) {
                newChain = newChain.add(chainB[keepIndex]);
            };
            keepIndex = keepIndex + 1;
        });
        chainB = newChain;
        rebuildChain.(chainB);
        updateGui.();
        postChain.("ChainB", chainB);
    };

    clearProcessorsA = {
        var sinkSym, sourceSym;
        sinkSym = chainA[0];
        sourceSym = chainA[chainA.size - 1];
        chainA = [sinkSym, sourceSym];
        rebuildChain.(chainA);
        updateGui.();
        postChain.("ChainA", chainA);
    };

    clearProcessorsB = {
        var sinkSym, sourceSym;
        sinkSym = chainB[0];
        sourceSym = chainB[chainB.size - 1];
        chainB = [sinkSym, sourceSym];
        rebuildChain.(chainB);
        updateGui.();
        postChain.("ChainB", chainB);
    };

    setChainA = { |newArray|
        var arr;
        arr = newArray.asArray.collect(_.asSymbol);
        chainA = arr;
        rebuildChain.(chainA);
        updateGui.();
        postChain.("ChainA", chainA);
    };

    setChainB = { |newArray|
        var arr;
        arr = newArray.asArray.collect(_.asSymbol);
        chainB = arr;
        rebuildChain.(chainB);
        updateGui.();
        postChain.("ChainB", chainB);
    };

    // Export convenience into tilde-space
    ~setSourceA        = setSourceA;
    ~setSourceB        = setSourceB;
    ~appendProcessorA  = appendProcessorA;
    ~appendProcessorB  = appendProcessorB;
    ~removeProcessorA  = removeProcessorA;
    ~removeProcessorB  = removeProcessorB;
    ~clearProcessorsA  = clearProcessorsA;
    ~clearProcessorsB  = clearProcessorsB;
    ~setChainA         = setChainA;
    ~setChainB         = setChainB;
});

// ---------- Cleanup ----------
window.onClose = {
    Ndef(\outA).stop;
    Ndef(\outB).stop;
    OSCdef(oscNameA).free;
    OSCdef(oscNameB).free;
    OSCdef(oscConsoleA).free;
    OSCdef(oscConsoleB).free;
    "Stopped and freed OSC responders.".postln;
};

window  // -> a Window
)
