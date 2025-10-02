// WindowLayout_Grid_WithSigChainsAndMeters_Debug.scd
// v1.9 — clearer layout, unified helpers, same behavior
// MD 20251001

/* Purpose
 - Create the "Layout Test" window with top-left/right text + meters and four lower panes.
 - Build initial A/B chains (srcA → outA, srcB → outB), sinks meter via SendPeakRMS.
 - Provide setSourceA/B, decimated console prints (ampdb), and robust meter value extraction.
 Style
 - var-first declarations everywhere; lowercase names; no non-local returns (^).
 - GUI updates via AppClock.defer; sinks read from \in.ar(2).
 - Use Ndef(left) <<> Ndef(right); return -> a Window.
*/

(
var window, make_pane, pane_color;
var top_left_text, top_left_meter, top_right_text, top_right_meter;
var osc_gui_a, osc_gui_b, osc_con_a, osc_con_b;
var chain_a, chain_b, ensure_stereo, rebuild_chain, chain_to_string;
var set_source_a, set_source_b, value_from_msg;
var dec_a = 0, dec_b = 0, dump_a = true, dump_b = true;

var existing;

// --- GUI ---

// --- safely close any prior "Layout Test" windows -- NOT SURE IF STILL NEEDED
existing = Window.allWindows.reject({ |x| x.isNil });
existing.do({ |w|
    if(w.isKindOf(Window) and: { w.name == "Layout Test" }, { w.close });
});


Window.allWindows.do({ | w | if(w.name == "Layout Test", { w.close }) });
window = Window("Layout Test", Rect(100, 100, 800, 600))
    .background_(Color.white)
    .front;

pane_color = Color(0.0, 0.35, 0.0);

make_pane = { |content, label|
    var label_view, inner, pane, inset;
    label_view = StaticText().string_(label).align_(\center)
        .stringColor_(Color.white).background_(pane_color);
    inner = VLayout(label_view, content);
    pane = UserView().layout_(inner);
    pane.drawFunc_({ |v|
        inset = 0.5;
        Pen.use {
            Pen.color = pane_color;
            Pen.width = 1;
            Pen.addRect(Rect(inset, inset, v.bounds.width - (2 * inset), v.bounds.height - (2 * inset)));
            Pen.stroke;
        };
    });
    pane
};

window.layout = GridLayout.rows(
    [
        make_pane.(HLayout(
            top_left_text  = TextView().editable_(false),
            top_left_meter = LevelIndicator().fixedWidth_(30)
        ), "Top Left Pane"),
        make_pane.(HLayout(
            top_right_text  = TextView().editable_(false),
            top_right_meter = LevelIndicator().fixedWidth_(30)
        ), "Top Right Pane")
    ],
    [
        make_pane.(VLayout(StaticText().align_(\center), TextView()), "System State"),
        make_pane.(VLayout(StaticText().align_(\center), TextView()), "Diagnostic Messages")
    ],
    [
        make_pane.(VLayout(StaticText().align_(\center), TextView()), "Choices"),
        make_pane.(VLayout(StaticText().align_(\center), TextView()), "Receiving Commands")
    ]
);

// --- Audio + chains + OSC ---
osc_gui_a = \rmsA_toGUI;
osc_gui_b = \rmsB_toGUI;
osc_con_a = \rmsA_console;
osc_con_b = \rmsB_console;

Server.default.waitForBoot({
    // SOURCES (stereo)
    Ndef(\srcZ, { Silent.ar(numChannels: 1) }); // spare
    Ndef(\srcA, { PinkNoise.ar(0.10 ! 2) });
    Ndef(\srcB, { SinOsc.ar([300, 301], mul: 0.20) });
    Ndef(\srcC, { LFSaw.ar([167, 171]).tanh * 0.18 });

    // SINKS (must read \in.ar(2)), meter to GUI
    // replyIDs A=1, B=2
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

    // Chain helpers
    ensure_stereo = { |key|
        var bus;
        bus = Ndef(key).bus;
        if(bus.isNil or: { bus.rate != \audio } or: { bus.numChannels != 2 }) {
            Ndef(key).ar(2);
        };
    };

    chain_to_string = { |an_array|
        var forward;
        forward = an_array.copy.reverse; // [source ... sink]
        forward.collect(_.asString).join(" → ")
    };

    rebuild_chain = { |an_array|
        var i;
        i = 0;
        if(an_array.size < 2) {
            "need at least [sink, source]".postln;
        }{
            an_array.do(ensure_stereo);
            i = 0;
            while({ i < (an_array.size - 1) }, {
                Ndef(an_array[i]) <<> Ndef(an_array[i + 1]); // left receives right at \in
                i = i + 1;
            });
            Ndef(an_array[0]).play(numChannels: 2);
        };
    };

    // Initial chains
    chain_a = [\outA, \srcA];
    chain_b = [\outB, \srcB];
    rebuild_chain.(chain_a);
    rebuild_chain.(chain_b);

    // Robust meter extractor: last numeric = final RMS from SendPeakRMS
    value_from_msg = { |msg|
        var v, sz;
        v = 0.0;
        if(msg.notNil) {
            sz = msg.size;
            if(sz >= 4) { v = msg[sz - 1].asFloat };
        };
        v.clip(0.0, 1.0)
    };

    // Rebind OSC (avoid duplicates on re-eval)
    { OSCdef(osc_gui_a).free; OSCdef(osc_gui_b).free; OSCdef(osc_con_a).free; OSCdef(osc_con_b).free; }.value;

    // GUI meters @ 20 Hz
    OSCdef(osc_gui_a, { |msg| { top_left_meter.value_(value_from_msg.(msg)) }.defer }, '/peakrmsA');
    OSCdef(osc_gui_b, { |msg| { top_right_meter.value_(value_from_msg.(msg)) }.defer }, '/peakrmsB');

    // Console prints (≈1 Hz via simple decimation)
    OSCdef(osc_con_a, { |msg|
        var v;
        if(dump_a) { "A first msg: %".format(msg).postln; dump_a = false }; // just the first message to see the actual formatting of it
        dec_a = dec_a + 1;
        if(dec_a >= 20) {
            v = value_from_msg.(msg).max(1e-6); // prevent ampdb on 0 which would be inf
            ("A level: " ++ (v.ampdb.round(0.1)) ++ " dB (" ++ v.round(0.003) ++ ")").postln;
			dec_a = 0; // e.g "A level: -38.5 dB (0.012)"
        };
    }, '/peakrmsA');

    OSCdef(osc_con_b, { |msg|
        var v;
        if(dump_b) { "B first msg: %".format(msg).postln; dump_b = false };
        dec_b = dec_b + 1;
        if(dec_b >= 20) {
            v = value_from_msg.(msg).max(1e-6);
            ("B level: " ++ (v.ampdb.round(0.1)) ++ " dB (" ++ v.round(0.003) ++ ")").postln;
            dec_b = 0;
        };
    }, '/peakrmsB');

    // Paint initial chain strings
    {
        top_left_text.string_(chain_to_string.(chain_a));
        top_right_text.string_(chain_to_string.(chain_b));
    }.defer;
});

// Convenience: change only the tail (source) of each chain
set_source_a = { |src_sym|
    var new_sym;
    new_sym = src_sym.asSymbol;
    chain_a[chain_a.size - 1] = new_sym;
    rebuild_chain.(chain_a);
    { top_left_text.string_(chain_to_string.(chain_a)) }.defer;
};
set_source_b = { |src_sym|
    var new_sym;
    new_sym = src_sym.asSymbol;
    chain_b[chain_b.size - 1] = new_sym;
    rebuild_chain.(chain_b);
    { top_right_text.string_(chain_to_string.(chain_b)) }.defer;
};
~setSourceA = set_source_a;
~setSourceB = set_source_b;

// Cleanup
window.onClose = {
    Ndef(\outA).stop;
    Ndef(\outB).stop;
    OSCdef(osc_gui_a).free;
    OSCdef(osc_gui_b).free;
    OSCdef(osc_con_a).free;
    OSCdef(osc_con_b).free;
};

window  // -> a Window
)