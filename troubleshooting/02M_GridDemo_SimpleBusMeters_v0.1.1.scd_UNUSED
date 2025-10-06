// 02M_GridDemo_SimpleBusMeters.scd
// v0.1.1
// MD 2025-09-29 13:20 BST

/* Purpose
 - Display a simple horizontal meter bar in the overlay, driven by your existing taps.
 - Uses MagicDisplay’s \busMeterA/\busMeterB SynthDefs (SendReply → /ampA,/ampB).
 - Avoids GridDemo’s TestMeter extension (which errors in your build).
Style
 - var-first; Server.default.bind for synths; AppClock-only for UI; no server.sync; idempotent.
*/

(
var aBus, bBus, whichChain, ensureGui, ensureOverlay, killOld, ensureSynths, mkBar, ampPath, oscKey;

aBus = 2001;  // your tap buses (confirmed by console)
bBus = 2002;
whichChain = \A; // change to \B if you prefer watching NEXT

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
    var host, hasOverlay;
    host = ~gui.tryPerform(\window).tryPerform(\view);
    hasOverlay = host.notNil and: { host.children.any({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" }) };
    if(hasOverlay.not) {
        // create overlay on the spot
        (
            var r, panel, title, stateBox, choicesBox, titleH, pad, width, height;
            r = host.bounds; width = 360; height = 220; pad = 8; titleH = 18;
            panel = CompositeView(host).name_("MDG_MINHUD");
            panel.background = Color(0,0,0,0.30);
            panel.bounds = Rect(r.width - (width + 12), 12, width, height);
            title = StaticText(panel).string_("MIN-HUD").font_(Font("Monaco", 13))
                   .stringColor_(Color(1,1,1,0.8)).bounds_(Rect(pad, pad, width - 2*pad, titleH));
            stateBox = TextView(panel).string_("(state line)").font_(Font("Monaco", 12))
                       .background_(Color(0,0,0,0.10)).stringColor_(Color.white)
                       .bounds_(Rect(pad, pad + titleH + 4, width - 2*pad, 22));
            choicesBox = TextView(panel).string_("(choices)").editable_(false)
                         .font_(Font("Monaco", 11)).background_(Color(0,0,0,0.10))
                         .stringColor_(Color(0.95,0.95,0.95))
                         .bounds_(Rect(pad, pad + titleH + 4 + 22 + 6, width - 2*pad, height - (titleH + 4 + 22 + 6 + pad)));
            ~hud_setState = { arg textString; AppClock.sched(0.0, { stateBox.string = textString.asString; nil }) };
            ~hud_setChoices = { arg linesArray; var s = (linesArray ? []).collect(_.asString).join("\n");
                                AppClock.sched(0.0, { choicesBox.string = s; nil }) };
        );
    };
};

killOld = {
    if(~mdg_meterSynthA.notNil) { ~mdg_meterSynthA.free; ~mdg_meterSynthA = nil };
    if(~mdg_meterSynthB.notNil) { ~mdg_meterSynthB.free; ~mdg_meterSynthB = nil };
    if(~mdg_meterOSC.notNil)    { ~mdg_meterOSC.free; ~mdg_meterOSC = nil };
    if(~mdg_meterView.notNil)   { ~mdg_meterView.remove; ~mdg_meterView = nil };
    ~mdg_meterVal = 0.0;
};

ensureSynths = {
    Server.default.bind({
        ~mdg_meterSynthA = Synth(\busMeterA, [\inBus, aBus, \rate, 24]);  // emits /ampA
        ~mdg_meterSynthB = Synth(\busMeterB, [\inBus, bBus, \rate, 24]);  // emits /ampB
    });
};

mkBar = {
    var host, overlay, bar, bnds, pad, h;

    host = ~gui.tryPerform(\window).tryPerform(\view);
    overlay = host.children.detect({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" });
    if(overlay.isNil) { "02M: overlay missing; aborting.".warn; ^nil };

    bnds = overlay.bounds; pad = 8; h = 8;

    bar = UserView(overlay);
    bar.name = "MDG_SIMPLE_METER";
    bar.bounds = Rect(pad, bnds.height - (h + pad), bnds.width - 2*pad, h);
    bar.background = Color(0,0,0,0.15);
    bar.drawFunc = { |uv|
        var w = uv.bounds.width, val = (~mdg_meterVal ? 0.0).clip(0, 1);
        Pen.fillColor = Color(0.2, 0.8, 0.3, 0.90);
        Pen.fillRect(Rect(0, 0, (w * val).max(1), h));
    };
    ~mdg_meterView = bar;

    ampPath = (whichChain == \A).if({ '/ampA' }, { '/ampB' });
    oscKey  = ("mdg_simple_" ++ ampPath.asString).asSymbol;

    ~mdg_meterOSC = OSCdef(oscKey, { |msg|
        var l, r, m;
        l = (msg.size > 3).if({ msg[3] }, { 0 }).asFloat;
        r = (msg.size > 4).if({ msg[4] }, { l }).asFloat;
        m = ((l + r) * 0.5).clip(0, 1);
        ~mdg_meterVal = ((~mdg_meterVal ? 0.0) * 0.7) + (m * 0.3);
        AppClock.sched(0.0, { ~mdg_meterView.tryPerform(\refresh); nil });
    }, ampPath);
};

AppClock.sched(0.00, {
    ensureGui.value;
    ensureOverlay.value;
    killOld.value;
    ensureSynths.value;
    AppClock.sched(0.05, { mkBar.value; nil });
    nil
});
)
