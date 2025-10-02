// LayoutTest_Quick_ChainChanges.scd
// v1.3 — programmatic tone set, compact pane binding, same one-liner API
// MD 20251001

/* Purpose
 - Provide calibrated tone sources, pulse sources, and a sweeping band-pass noise.
 - Offer single-line pane text updates targeting the existing "Layout Test" panes.
 - Keep your ~setSourceA/~setSourceB and avoid rebuilding unless asked.
 Style
 - var-first declarations; lowercase identifiers; AppClock.defer for GUI updates.
 - Sources are Ndefs; sinks/processors use \in.ar(2) (handled in the window script).
*/

(
var make_cal_tones, make_pulses, make_bp_sweep;
var db_list, make_tone;
var bind_panes, find_window_by_name, find_text_by_pane_label;

// --- Calibration tones (stereo) programmatically
db_list = [-6, -12, -18, -24, -30];

make_tone = { |name_sym, db_val|
    var amp;
    amp = db_val.dbamp;
    Ndef(name_sym, {
        var freq, sig;
        freq = \freq.kr(100).max(10);
        sig = SinOsc.ar([freq, freq], 0, amp);
        sig
    });
};

make_cal_tones = {
    make_tone.(\tone_m0,    0);
    db_list.do({ |db| make_tone.(("tone_m" ++ db.neg.asInteger).asSymbol, db) });
    make_tone.(\tone_m128, -128);
};

// --- Pulses
make_pulses = {
    // Clicks
    Ndef(\pulse_click, {
        var rate, env, noise, sig;
        rate = \rate.kr(1.0).clip(0.1, 10.0);
        env  = Decay2.kr(Impulse.kr(rate), 0.002, 0.08);
        noise = PinkNoise.ar([0.5, 0.5]);
        sig = noise * env;
        sig
    });

    // Decaying tone "ping"
    Ndef(\pulse_tone, {
        var rate, freq, env, tone, sig;
        rate = \rate.kr(1.0).clip(0.1, 10.0);
        freq = \freq.kr(1000).clip(50, 8000);
        env  = Decay2.kr(Impulse.kr(rate), 0.005, \dec.kr(0.3).clip(0.01, 2.0));
        tone = SinOsc.ar([freq, freq]);
        sig  = (tone * env) * 0.8;
        sig
    });

    // Pulse train gate on noise
    Ndef(\pulse_train, {
        var rate, duty, gate_ctl, noise, sig;
        rate = \rate.kr(2.0).clip(0.1, 20.0);
        duty = \duty.kr(0.25).clip(0.01, 0.95);
        gate_ctl = LFPulse.kr(rate, 0, duty).lag(0.001);
        noise = WhiteNoise.ar([0.4, 0.4]);
        sig = noise * gate_ctl;
        sig
    });
};

// --- Band-passed noise with sweeping center frequency
make_bp_sweep = {
    Ndef(\bp_sweep, {
        var base, range, rate, center, rq, src, sig;
        base = \base.kr(200).clip(20, 10000);
        range = \range.kr(5000).clip(0, 18000);
        rate = \rate.kr(0.07).clip(0.005, 2.0);
        center = base + (range * (LFTri.kr(rate).range(0, 1)));
        rq = \rq.kr(0.15).clip(0.01, 0.9);
        src = PinkNoise.ar([0.5, 0.5]);
        sig = BPF.ar(src, center, rq) * 1.2;
        sig
    });
};

// --- Pane text helpers (bind once, then ~lt_send.(\left, "…"))
find_window_by_name = { |target|
    var match;
    match = Window.allWindows.detect({ |w| w.name == target });
    match
};

find_text_by_pane_label = { |root_view, pane_label|
    var found_static, result, search_static, collect_text;
    found_static = nil; result = nil;

    search_static = { |view|
        var i, n, child;
        i = 0; n = view.children.size;
        while({ i < n }, {
            child = view.children[i];
            if(child.isKindOf(StaticText) and: { child.string == pane_label }) {
                found_static = child;
            }{
                search_static.(child);
            };
            i = i + 1;
        });
    };

    collect_text = { |view|
        var i, n, child;
        i = 0; n = view.children.size;
        while({ i < n }, {
            child = view.children[i];
            if(child.isKindOf(TextView)) {
                if(result.isNil) { result = child };
            }{
                collect_text.(child);
            };
            i = i + 1;
        });
    };

    search_static.(root_view);
    if(found_static.notNil and: { found_static.parent.notNil }) {
        collect_text.(found_static.parent);
    };
    result
};

bind_panes = {
    var win, root, left, right, system, diag, choices, recv, map;
    win = find_window_by_name.("Layout Test");
    if(win.isNil) {
        "Layout Test window not found. Open the window script first.".postln;
    }{
        root    = win.view;
        left    = find_text_by_pane_label.(root, "Top Left Pane");
        right   = find_text_by_pane_label.(root, "Top Right Pane");
        system  = find_text_by_pane_label.(root, "System State");
        diag    = find_text_by_pane_label.(root, "Diagnostic Messages");
        choices = find_text_by_pane_label.(root, "Choices");
        recv    = find_text_by_pane_label.(root, "Receiving Commands");
        map = IdentityDictionary[
            \left   -> left,
            \right  -> right,
            \system -> system,
            \diag   -> diag,
            \choices-> choices,
            \recv   -> recv
        ];
        ~lt_panes = map;
        "Layout Test panes bound: %".format(map.keys).postln;
    };
};

// Public API: set pane text by key (\left, \right, \system, \diag, \choices, \recv)
~lt_send = { |pane_key, a_string|
    var panes, view_to_set, text_string, win;
    panes = ~lt_panes;
    text_string = a_string.asString;
    if(panes.isNil) { bind_panes.(); panes = ~lt_panes };
    if(panes.notNil) {
        view_to_set = panes[pane_key.asSymbol];
        if(view_to_set.notNil) {
            { view_to_set.string_(text_string) }.defer;
        }{
            win = find_window_by_name.("Layout Test");
            if(win.notNil) {
                "Pane '%' not found (bound keys: %)".format(pane_key, panes.keys).postln;
            }{
                "Layout Test window not found.".postln;
            };
        };
    };
};

// Define sources
make_cal_tones.();
make_pulses.();
make_bp_sweep.();

"Quick changes ready: tones (tone_m6..tone_m30), pulses (pulse_click, pulse_tone, pulse_train), sweep (bp_sweep).".postln;
)