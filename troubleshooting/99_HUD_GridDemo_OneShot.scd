// 99_HUD_GridDemo_OneShot.scd
// v0.1.1
// MD 2025-09-29 14:05 BST

/* Purpose
 - One-shot HUD bring-up for GridDemo (non-pulsing), replacing multiple files:
   • close old MagicDisplayGUI windows, bring up GridDemo, set ~gui
   • solid A highlight
   • overlay at top-right with STATE + CHOICES (StaticText only; guaranteed visible)
   • thicker moving meter bar driven by OSC taps (/ampA, /ampB, /md/levels_gui, /md/levels)
   • push demo STATE/CHOICES text
Style
 - var-first; AppClock-only for UI; no server.sync; idempotent; nil-safe; no caret-returns in closures.
Run
 - Run after audio/tap steps (e.g., after 02S_AssertStereo_ChainAB_and_Retap_SAFE.scd).
 - To monitor NEXT (B) instead of CURRENT (A), set wantB = true below.
*/

(
var wantB;
var closeWindows, makeGridDemo, ensureReady, solidA, buildOverlay, pushDemoText;
var addMeterBar, startOscDefs, stopOldOscDefs, parseVal, retry;

// ===== CONFIG =====
wantB = false;  // false = monitor CURRENT (A); true = monitor NEXT (B)

// ===== HELPERS =====

closeWindows = {
    Window.allWindows
    .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
    .do(_.close);
};

makeGridDemo = {
    ~gui = MagicDisplayGUI_GridDemo.new;         // controller (not a Window)
    if(~gui.respondsTo(\window)) {
        ~gui.window.front.alwaysOnTop_(true);
    };
};

ensureReady = { arg triesLeft = 20, thenDo = { } ;
    // Wait until ~gui.window.view is non-nil and has a Rect bounds
    AppClock.sched(0.03, {
        var win, host, ok;
        win = ~gui.tryPerform(\window);
        host = win.tryPerform(\view);
        ok = host.notNil and: { host.bounds.notNil };
        if(ok) { thenDo.value(host); nil } {
            if(triesLeft <= 0) { "99: window/view not ready; giving up.".warn; nil } {
                ensureReady.value(triesLeft - 1, thenDo);
            }
        }
    });
};

solidA = {
    if(~gui.respondsTo(\highlightCurrentColumn)) { ~gui.highlightCurrentColumn(\chainA) };
};

buildOverlay = { arg host;
    var r, panel, title, stateLabel, choicesLabel, choicesBox;
    var pad, width, height, titleH, stateH, lineH;

    // Kill any old overlay
    host.children.select({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" }).do(_.remove);

    // Layout numbers (kept simple & safe)
    r = host.bounds;
    width = 360; height = 190;
    pad = 8; titleH = 16; stateH = 18; lineH = 14;

    panel = CompositeView(host);
    panel.name = "MDG_MINHUD";
    panel.background = Color(0,0,0,0.30);
    // no .border or decorators (avoids internal draw quirks)
    panel.bounds = Rect(r.width - (width + 12), 10, width, height);
    panel.front;

    title = StaticText(panel);
    title.string = "MIN-HUD";
    title.font   = Font("Monaco", 12);
    title.stringColor = Color(1,1,1,0.85);
    title.bounds = Rect(pad, pad, width - 2*pad, titleH);

    stateLabel = StaticText(panel);
    stateLabel.string = "(state)";
    stateLabel.font   = Font("Monaco", 11);
    stateLabel.stringColor = Color(1,1,1,0.95);
    stateLabel.bounds = Rect(pad, pad + titleH + 4, width - 2*pad, stateH);

    choicesLabel = StaticText(panel);
    choicesLabel.string = "CHOICES:";
    choicesLabel.font   = Font("Monaco", 11);
    choicesLabel.stringColor = Color(1,1,1,0.85);
    choicesLabel.bounds = Rect(pad, pad + titleH + 4 + stateH + 6, width - 2*pad, lineH);

    choicesBox = StaticText(panel);
    choicesBox.string = "(choices)";
    choicesBox.font   = Font("Monaco", 10);
    choicesBox.stringColor = Color(0.95,0.95,0.95);
    choicesBox.bounds = Rect(
        pad,
        pad + titleH + 4 + stateH + 6 + lineH + 2,
        width - 2*pad,
        height - (titleH + 4 + stateH + 6 + lineH + 2 + pad)
    );

    // Export helpers
    ~hud_setState = { arg s;
        AppClock.sched(0.0, { stateLabel.string = s.asString; nil });
    };
    ~hud_setChoices = { arg lines;
        var txt;
        txt = (lines ? []).collect(_.asString).join("\n");
        AppClock.sched(0.0, { choicesBox.string = (txt.size > 0).if({ txt }, { "—" }); nil });
    };

    // Re-anchor after any resize
    if(~gui.respondsTo(\window)) {
        ~gui.window.onResize = {
            var rb = host.bounds;
            panel.bounds = Rect(rb.width - (width + 12), 10, width, height);
            panel.front;
        };
    };

    // Create thicker meter bar at bottom of the overlay
    addMeterBar.value(panel);
};

addMeterBar = { arg overlay;
    var bnds, pad, h, bar;

    bnds = overlay.bounds; pad = 8; h = 16;

    // Remove any previous bar if re-running
    overlay.children.select({ |v| (v.tryPerform(\name) ? "") == "MDG_SIMPLE_METER" }).do(_.remove);

    bar = UserView(overlay);
    bar.name = "MDG_SIMPLE_METER";
    bar.bounds = Rect(pad, bnds.height - (h + pad), bnds.width - 2*pad, h);
    bar.background = Color(0,0,0,0.10);
    bar.drawFunc = { |uv|
        var w, val;
        w = uv.bounds.width;
        val = (~mdg_meterVal ? 0.0).clip(0, 1);
        Pen.fillColor = Color(0.20, 0.85, 0.35, 0.95);
        Pen.fillRect(Rect(0, 0, (w * val).max(1), h));
    };
    bar.front;
    ~mdg_meterView = bar;
    ~mdg_meterVal  = 0.0;
};

stopOldOscDefs = {
    if(~mdg_meterOSC_amp.notNil) { ~mdg_meterOSC_amp.free; ~mdg_meterOSC_amp = nil };
    if(~mdg_meterOSC_lvl.notNil) { ~mdg_meterOSC_lvl.free; ~mdg_meterOSC_lvl = nil };
};

parseVal = { arg msg, wantNext;
    var floats, vL, vR, v;
    floats = msg.select({ |x| x.isNumber }).collect(_.asFloat);
    if(msg[0] == '/ampA' or: { msg[0] == '/ampB' }) {
        vL = (floats.size > 2).if({ floats[2] }, { 0.0 });
        vR = (floats.size > 3).if({ floats[3] }, { vL });
        v  = ((vL + vR) * 0.5).clip(0, 1);
        ^v;
    };
    if(msg[0] == '/md/levels_gui' or: { msg[0] == '/md/levels' }) {
        if(floats.size >= 4) {
            if(wantNext.not) { vL = floats.at(floats.size - 4); vR = floats.at(floats.size - 3) }
            { vL = floats.at(floats.size - 2); vR = floats.at(floats.size - 1) };
            v = ((vL + vR) * 0.5).clip(0, 1);
            ^v;
        }{
            v = (floats.size > 0).if({ floats.mean.clip(0,1) }, { 0.0 });
            ^v;
        };
    };
    ^0.0;
};

startOscDefs = {
    var wantNext, ampPath;
    wantNext = wantB;

    stopOldOscDefs.value;

    // 1) Prefer /ampA or /ampB if present (bus meters)
    ampPath = (wantNext.not).if({ '/ampA' }, { '/ampB' });
    ~mdg_meterOSC_amp = OSCdef(("mdg_meter_" ++ ampPath.asString).asSymbol, { |msg|
        var raw = parseVal.(msg, wantNext);
        ~mdg_meterVal = ((~mdg_meterVal ? 0.0) * 0.7) + (raw * 0.3);
        AppClock.sched(0.0, { ~mdg_meterView.tryPerform(\refresh); nil });
    }, ampPath);

    // 2) Also listen to /md/levels_gui and /md/levels explicitly
    ~mdg_meterOSC_lvl = OSCdef(\mdg_meter_levels_mux, { |msg|
        if(msg[0] == '/md/levels_gui' or: { msg[0] == '/md/levels' }) {
            var raw = parseVal.(msg, wantNext);
            ~mdg_meterVal = ((~mdg_meterVal ? 0.0) * 0.7) + (raw * 0.3);
            AppClock.sched(0.0, { ~mdg_meterView.tryPerform(\refresh); nil });
        };
    }, nil); // catch all; we filter inside
    ("99: meter listening for chain " ++ (wantNext.if({ "B" }, { "A" })) ++ " on /ampA/B + /md/levels(_gui)").postln;
};

pushDemoText = {
    (~hud_setState !? { ~hud_setState.("Mode: treeNav · A=ACTIVE") });
    (~hud_setChoices !? {
        ~hud_setChoices.([
            "fret 3 → add",
            "fret 5 → timebased",
            "fret 7 → modulation",
            "fret 9 → filter"
        ])
    });
};

// ===== RUN (guarded sequence) =====

AppClock.sched(0.00, { closeWindows.value; nil });
AppClock.sched(0.08, {
    makeGridDemo.value;
    solidA.value;
    ensureReady.value(20, { arg host;
        buildOverlay.value(host);
        // Give layout a breath, then meters + text
        AppClock.sched(0.06, {
            addMeterBar.value(host.children.detect({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" }));
            startOscDefs.value;
            pushDemoText.value;
            nil
        });
        nil
    });
    nil
});
)
