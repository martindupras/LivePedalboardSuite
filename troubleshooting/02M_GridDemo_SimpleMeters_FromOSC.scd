// 02M_GridDemo_SimpleMeters_FromOSC.scd
// v0.2.0
// MD 2025-09-29 13:42 BST

/* Purpose
 - Show a simple horizontal meter bar in the MIN-HUD overlay, driven directly by existing OSC taps.
 - Listens to any of these (whichever arrives first will drive the bar): /md/levels_gui, /md/levels, /ampA, /ampB.
 - Defaults to CURRENT (A). Set whichChain = \B to monitor NEXT instead.
Style
 - var-first; AppClock-only UI; no server.sync; idempotent.
*/

(
var whichChain, ensureGui, ensureOverlay, killOld, mkBar, startListeners, parseMsg, pickVal;

whichChain = \A;   // change to \B if you want NEXT

ensureGui = {
    if(~gui.isNil) {
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        ~gui = MagicDisplayGUI_GridDemo.new;
    };
    if(~gui.respondsTo(\window)) { ~gui.window.front.alwaysOnTop_(true) };
};

ensureOverlay = {
    var host, overlay;
    host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.isNil) { "02M: host view is nil; aborting.".warn; ^nil };
    overlay = host.children.detect({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" });
    if(overlay.isNil) {
        "02M: creating overlay (02H inline)".postln;
        thisProcess.interpreter.executeFile(Platform.userHomeDir +/+ "02H_GridDemo_MinHUD_Overlay.scd");
    };
};

killOld = {
    if(~mdg_meterOSC_A.notNil) { ~mdg_meterOSC_A.free; ~mdg_meterOSC_A = nil };
    if(~mdg_meterOSC_B.notNil) { ~mdg_meterOSC_B.free; ~mdg_meterOSC_B = nil };
    if(~mdg_meterView.notNil)  { ~mdg_meterView.remove; ~mdg_meterView = nil };
    ~mdg_meterVal = 0.0;
};

mkBar = {
    var host, overlay, bar, bnds, pad, h;
    host = ~gui.tryPerform(\window).tryPerform(\view);
    overlay = host.children.detect({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" });
    if(overlay.isNil) { "02M: overlay missing; aborting.".warn; ^nil };

    bnds = overlay.bounds; pad = 8; h = 16;  // thicker bar

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
};

// Extract a normalized 0..1 value from a variety of message shapes
pickVal = { arg msg, wantB = false;
    var floats, vL, vR, v;
    // Common shapes:
    //  - ['/ampA', node, l, r] or ['/ampB', node, l, r]
    //  - ['/md/levels_gui', ..., lA, rA, lB, rB] (varies by sender)
    //  - ['/md/levels', ..., numbers...]         (varies by sender)
    floats = msg.select({ |x| x.isNumber }).collect(_.asFloat);
    if(msg[0] == '/ampA' or: { msg[0] == '/ampB' }) {
        vL = (floats.size > 2).if({ floats[2] }, { 0.0 });
        vR = (floats.size > 3).if({ floats[3] }, { vL });
        v  = ((vL + vR) * 0.5).clip(0, 1);
        ^v;
    };
    if(msg[0] == '/md/levels_gui' or: { msg[0] == '/md/levels' }) {
        // Heuristic: last 4 floats are usually [lA, rA, lB, rB] (sanitised)
        if(floats.size >= 4) {
            if(wantB.not) {
                vL = floats.at(floats.size - 4);
                vR = floats.at(floats.size - 3);
            }{
                vL = floats.at(floats.size - 2);
                vR = floats.at(floats.size - 1);
            };
            v = ((vL + vR) * 0.5).clip(0, 1);
            ^v;
        }{
            // Fallback: mean of all floats
            v = (floats.size > 0).if({ floats.mean.clip(0,1) }, { 0.0 });
            ^v;
        };
    };
    ^0.0;
};

startListeners = {
    var wantB, pathA1, pathA2, pathB1, pathB2, chainLabel;
    wantB = (whichChain == \B);
    chainLabel = (wantB.not).if({ "A" }, { "B" });

    pathA1 = (wantB.not).if({ '/ampA' }, { '/ampB' });
    pathA2 = (wantB.not).if({ '/md/levels_gui' }, { '/md/levels_gui' }); // we filter in pickVal
    pathB1 = (wantB.not).if({ '/ampA' }, { '/ampB' });  // both defs update same var
    pathB2 = (wantB.not).if({ '/md/levels' }, { '/md/levels' });

    // Free any previous listeners
    if(~mdg_meterOSC_A.notNil) { ~mdg_meterOSC_A.free };
    if(~mdg_meterOSC_B.notNil) { ~mdg_meterOSC_B.free };

    // Listener 1: /ampA or /ampB
    ~mdg_meterOSC_A = OSCdef(("mdg_meter_" ++ pathA1.asString).asSymbol, { |msg|
        var raw, sm;
        raw = pickVal.(msg, wantB);
        sm  = ((~mdg_meterVal ? 0.0) * 0.7) + (raw * 0.3);
        ~mdg_meterVal = sm;
        AppClock.sched(0.0, { ~mdg_meterView.tryPerform(\refresh); nil });
    }, pathA1);

    // Listener 2: /md/levels_gui and /md/levels
    ~mdg_meterOSC_B = OSCdef(("mdg_meter_mix").asSymbol, { |msg|
        var raw, sm;
        if(msg[0] == '/md/levels_gui' or: { msg[0] == '/md/levels' }) {
            raw = pickVal.(msg, wantB);
            sm  = ((~mdg_meterVal ? 0.0) * 0.7) + (raw * 0.3);
            ~mdg_meterVal = sm;
            AppClock.sched(0.0, { ~mdg_meterView.tryPerform(\refresh); nil });
        };
    }, nil); // nil path: catch-all, we'll filter inside
    // Note: if the catch-all is too broad, change to two OSCdef with explicit paths.
    ("02M: meter listening for chain " ++ chainLabel ++ " on /ampA/B + /md/levels(_gui)").postln;
};

// Run
AppClock.sched(0.00, {
    ensureGui.value;
    ensureOverlay.value;
    killOld.value;
    mkBar.value;
    startListeners.value;
    nil
});
)
