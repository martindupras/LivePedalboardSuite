// LayoutTest_Quick_ChainChanges.scd
// v1.2 - calibrated test signals, pulses, sweeping BP noise; pane text one-liners for Layout Test
// MD 20250930

/* Purpose
   - Augment an already-running "Layout Test" session (v1.8) with ready-to-use test sources:
       • 100 Hz tones at -6/-12/-18/-24/-30 dBFS (stereo)
       • pulse clicks and decaying tone pulses for echo testing
       • band-passed noise with a sweeping center frequency
   - Provide one-line commands to:
       • switch A/B sources quickly
       • update text in the "Layout Test" panes (left/right/system/diag/choices/recv)
   - No new windows; no chain rebuild unless you choose to rewire explicitly.

   Style
   - var-first declarations in every function/block
   - lowercase names, descriptive identifiers
   - Ndef(left) <<> Ndef(right); sinks/processors use \in.ar(2)
   - no non-local returns (^); AppClock.defer for GUI updates
*/

(
// ---------- Setup: test sources + pane helpers (evaluate this block once) ----------
var defineCalTones, definePulses, defineSweepingNoise, dbList;
var bindLayoutPanes, findTextViewByPaneLabel, findWindowByName;

/*** Calibration tones (100 Hz, stereo) at set dBFS ***/
dbList = [-6, -12, -18, -24, -30];

defineCalTones = {
    var freqDefault, makeTone;
    freqDefault = 100;
    makeTone = { |nameSym, dbVal|
        var amp;
        amp = dbVal.dbamp;  // dBFS -> linear amplitude
        Ndef(nameSym, {
            var freq, sig;
            freq = \freq.kr(freqDefault).max(10);
            sig = SinOsc.ar([freq, freq], 0, amp);
            sig
        });
    };
    makeTone.(\tone_m0,  0);
    makeTone.(\tone_m6,  -6);
    makeTone.(\tone_m12, -12);
    makeTone.(\tone_m18, -18);
    makeTone.(\tone_m24, -24);
    makeTone.(\tone_m30, -30);
	makeTone.(\tone_m128, -128);

};

/*** Pulse sources (for echo audibility) ***/
definePulses = {
    // Wideband click bursts at low rate
    Ndef(\pulse_click, {
        var rate, env, noise, sig;
        rate = \rate.kr(1.0).clip(0.1, 10.0);          // clicks per second
        env  = Decay2.kr(Impulse.kr(rate), 0.002, 0.08); // short burst envelope
        noise = PinkNoise.ar([0.5, 0.5]);
        sig = noise * env; // stereo
        sig
    });

    // Decaying 1 kHz tone "ping" at adjustable rate
    Ndef(\pulse_tone, {
        var rate, freq, env, tone, sig;
        rate = \rate.kr(1.0).clip(0.1, 10.0);
        freq = \freq.kr(1000).clip(50, 8000);
        env  = Decay2.kr(Impulse.kr(rate), 0.005, \dec.kr(0.3).clip(0.01, 2.0));
        tone = SinOsc.ar([freq, freq]);
        sig  = (tone * env) * 0.8;
        sig
    });

    // Pulse train (gate) on noise for rhythmic echoes
    Ndef(\pulse_train, {
        var rate, duty, gateCtl, noise, sig;
        rate = \rate.kr(2.0).clip(0.1, 20.0);
        duty = \duty.kr(0.25).clip(0.01, 0.95);
        gateCtl = LFPulse.kr(rate, 0, duty).lag(0.001); // soften edges slightly
        noise = WhiteNoise.ar([0.4, 0.4]);
        sig = noise * gateCtl;
        sig
    });
};

/*** Band-passed noise with sweeping center frequency ***/
defineSweepingNoise = {
    Ndef(\bp_sweep, {
        var base, range, sweepRate, center, rq, src, sig;
        base      = \base.kr(200).clip(20, 10000);
        range     = \range.kr(5000).clip(0, 18000);
        sweepRate = \rate.kr(0.07).clip(0.005, 2.0);   // Hz of sweep
        center    = base + (range * (LFTri.kr(sweepRate).range(0, 1)));
        rq        = \rq.kr(0.15).clip(0.01, 0.9);
        src       = PinkNoise.ar([0.5, 0.5]);
        sig       = BPF.ar(src, center, rq) * 1.2;     // modest makeup gain
        sig
    });
};

/*** Helpers to update text in the existing "Layout Test" panes ***/
findWindowByName = { |targetName|
    var match;
    match = Window.allWindows.detect({ |win| win.name == targetName });
    match
};

// This tries to find the TextView that pairs with a pane label (StaticText string)
findTextViewByPaneLabel = { |rootView, paneLabelString|
    var foundStatic, paneTextView, searchStatic, collectTextViews;

    foundStatic = nil;
    paneTextView = nil;

    searchStatic = { |view|
        var childIndex, childCount, childView;
        childIndex = 0;
        childCount = view.children.size;
        while({ childIndex < childCount }, {
            childView = view.children[childIndex];
            if(childView.isKindOf(StaticText) and: { childView.string == paneLabelString }) {
                foundStatic = childView;
            }{
                searchStatic.(childView);
            };
            childIndex = childIndex + 1;
        });
    };

    collectTextViews = { |view|
        var childIndex, childCount, childView;
        childIndex = 0;
        childCount = view.children.size;
        while({ childIndex < childCount }, {
            childView = view.children[childIndex];
            if(childView.isKindOf(TextView)) {
                if(paneTextView.isNil) { paneTextView = childView; };
            }{
                collectTextViews.(childView);
            };
            childIndex = childIndex + 1;
        });
    };

    // locate the StaticText with the pane label, then search its parent subtree for the first TextView
    searchStatic.(rootView);
    if(foundStatic.notNil and: { foundStatic.parent.notNil }) {
        collectTextViews.(foundStatic.parent);
    };

    paneTextView
};

// Cache and simple API
bindLayoutPanes = {
    var win, root, leftText, rightText, systemText, diagText, choicesText, recvText, map;

    win = findWindowByName.("Layout Test");
    if(win.isNil) {
        "Layout Test window not found. Open WindowLayout_Grid_WithSigChainsAndMeters_Debug.scd first.".postln;
    }{
        root = win.view;

        leftText    = findTextViewByPaneLabel.(root, "Top Left Pane");
        rightText   = findTextViewByPaneLabel.(root, "Top Right Pane");
        systemText  = findTextViewByPaneLabel.(root, "System State");
        diagText    = findTextViewByPaneLabel.(root, "Diagnostic Messages");
        choicesText = findTextViewByPaneLabel.(root, "Choices");
        recvText    = findTextViewByPaneLabel.(root, "Receiving Commands");

        map = IdentityDictionary[
            \left   -> leftText,
            \right  -> rightText,
            \system -> systemText,
            \diag   -> diagText,
            \choices-> choicesText,
            \recv   -> recvText
        ];

        ~lt_panes = map;
        "Layout Test panes bound: %".format(map.keys).postln;
    };
};

// Public: set pane text by key (\left, \right, \system, \diag, \choices, \recv)
~lt_send = { |paneKey, aString|
    var panes, win, viewToSet, textString;
    panes = ~lt_panes;
    textString = aString.asString;
    if(panes.isNil) { bindLayoutPanes.(); panes = ~lt_panes; };
    if(panes.notNil) {
        viewToSet = panes[paneKey.asSymbol];
        if(viewToSet.notNil) {
            { viewToSet.string_(textString) }.defer;
        }{
            win = findWindowByName.("Layout Test");
            if(win.notNil) {
                "Pane '%' not found in Layout Test (bound keys: %).".format(paneKey, panes.keys).postln;
            }{
                "Layout Test window not found.".postln;
            };
        };
    };
};

// Define sources
defineCalTones.();
definePulses.();
defineSweepingNoise.();

// Convenience: quick status ping
"Quick Chain Changes ready: tones (tone_m6..tone_m30), pulses (pulse_click, pulse_tone, pulse_train), sweep (bp_sweep).".postln;
);


// ======================================================================
// ONE-LINERS (evaluate any of these as needed)
// ======================================================================

// ---------- 1) Switch A/B sources (updates the Top Left/Right pane text via your ~setSourceA/B) ----------
~setSourceA.(\tone_m0);
~setSourceA.(\tone_m6);
~setSourceA.(\tone_m12);
~setSourceA.(\tone_m18);
~setSourceA.(\tone_m24);
~setSourceA.(\tone_m30);
~setSourceA.(\tone_m128);
~setSourceA.(\pulse_click);
~setSourceA.(\pulse_tone);
~setSourceA.(\pulse_train);
~setSourceA.(\bp_sweep);

~setSourceB.(\tone_m0);
~setSourceB.(\tone_m6);
~setSourceB.(\tone_m12);
~setSourceB.(\tone_m18);
~setSourceB.(\tone_m24);
~setSourceB.(\tone_m30);
~setSourceB.(\tone_m128);
~setSourceB.(\pulse_click);
~setSourceB.(\pulse_tone);
~setSourceB.(\pulse_train);
~setSourceB.(\bp_sweep);

// ---------- 2) Tweak source parameters live (no chain rebuild needed) ----------
// Tones: set tone frequency for any calibration tone
Ndef(\tone_m6).set(\freq, 100);
Ndef(\tone_m12).set(\freq, 100);
Ndef(\tone_m18).set(\freq, 100);
Ndef(\tone_m24).set(\freq, 100);
Ndef(\tone_m30).set(\freq, 100);

// Pulses: rate / decay / pulse width
Ndef(\pulse_click).set(\rate, 1.0);     // clicks per second
Ndef(\pulse_tone).set(\rate, 1.2, \freq, 800, \dec, 0.25);
Ndef(\pulse_train).set(\rate, 2.0, \duty, 0.25);

// Band-passed sweep: base frequency, range, sweep rate, and resonance (rq)
Ndef(\bp_sweep).set(\base, 200, \range, 5000, \rate, 0.07, \rq, 0.15);
Ndef(\bp_sweep).set(\base, 100, \range, 8000, \rate, 0.12, \rq, 0.10);

// ---------- 3) Send text to Layout Test panes (single-liners) ----------
// First bind once (if not already bound):
~lt_send.(\system, "System ready — quick changes loaded.");
~lt_send.(\diag,   "Re-evaluated quick chain helpers at " ++ Date.getDate.stamp );
~lt_send.(\choices,"A: tone_m12 | B: pulse_train");
~lt_send.(\recv,   "Waiting for commands…");
~lt_send.(\left,   "Chain A: swap via ~setSourceA.(\\tone_m6)");
~lt_send.(\right,  "Chain B: swap via ~setSourceB.(\\bp_sweep)");

// ---------- 4) (Optional) Direct rewire one-liners (audio + meters update immediately; GUI labels do not) ----------
// A direct to specific source:
(Ndef(\outA) <<> Ndef(\tone_m6);   Ndef(\outA).play(numChannels: 2););
(Ndef(\outA) <<> Ndef(\pulse_tone); Ndef(\outA).play(numChannels: 2););

// B direct to specific source:
(Ndef(\outB) <<> Ndef(\bp_sweep);   Ndef(\outB).play(numChannels: 2););
(Ndef(\outB) <<> Ndef(\pulse_click); Ndef(\outB).play(numChannels: 2););

// ---------- 5) Quick recovery (go back to your original A/B defaults) ----------
~setSourceA.(\srcA);
~setSourceB.(\srcA);
