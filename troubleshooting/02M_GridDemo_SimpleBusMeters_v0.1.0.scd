// 02M_GridDemo_SimpleBusMeters.scd
// v0.1.0
// MD 20250929-13:10

/* Purpose
   - Show a simple horizontal meter bar driven by your existing taps (A=2001, B=2002).
   - Avoid GridDemo TestMeter extension (which warns and OOC-returns in your build).
   - Instantiates \busMeterA / \busMeterB Synths if needed and listens to /ampA or /ampB.
Style
   - var-first; Server.default.bind for synths; AppClock-only for UI; no server.sync; idempotent.
*/

(
var aBus, bBus, whichChain, ensureGui, ensureOverlay, ensureSynths, killOld, mkBar, ampKey, oscKey;

aBus = 2001;  bBus = 2002;
whichChain = \A; // change to \B if you want to view NEXT

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
    var host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.notNil) {
        if(host.children.any({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" }).not) {
            // bring up overlay if missing
            "02M: Overlay missing; creating…".postln;
            thisProcess.interpreter.executeFile(
                Platform.userHomeDir +/+ "02H_GridDemo_MinHUD_Overlay.scd"
            )
        };
    };
};

killOld = {
    // free previous synths + OSCdefs + view if re-running
    if(~mdg_meterSynthA.notNil) { ~mdg_meterSynthA.free; ~mdg_meterSynthA = nil };
    if(~mdg_meterSynthB.notNil) { ~mdg_meterSynthB.free; ~mdg_meterSynthB = nil };
    if(~mdg_meterOSC.notNil)    { ~mdg_meterOSC.free; ~mdg_meterOSC = nil };
    if(~mdg_meterView.notNil)   { ~mdg_meterView.remove; ~mdg_meterView = nil };
    ~mdg_meterVal = 0.0;
};

ensureSynths = {
    Server.default.bind({
        // Define/instantiate lightweight bus meters (MagicDisplay provides the SynthDefs)
        ~mdg_meterSynthA = Synth(\busMeterA, [\inBus, aBus, \rate, 24]);
        ~mdg_meterSynthB = Synth(\busMeterB, [\inBus, bBus, \rate, 24]);
    });
};

mkBar = {
    var host, overlay, bar, bnds, pad, h;

    host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.isNil) { "02M: host view is nil; aborting.".warn; ^nil };

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

    // OSC driver (choose /ampA or /ampB)
    ampKey = (whichChain == \A).if({ '/ampA' }, { '/ampB' });
    oscKey = ("mdg_simple_" ++ ampKey.asString).asSymbol;

    ~mdg_meterOSC = OSCdef(oscKey, { |msg|
        var l = (msg.size > 3).if({ msg[3] }, { 0 }).asFloat;
        var r = (msg.size > 4).if({ msg[4] }, { l }).asFloat;
        var m = ((l + r) * 0.5).clip(0, 1);
        ~mdg_meterVal = ((~mdg_meterVal ? 0.0) * 0.7) + (m * 0.3); // smooth
        AppClock.sched(0.0, { ~mdg_meterView.tryPerform(\refresh); nil });
    }, ampKey);
};

// Run
AppClock.sched(0.00, {
    ensureGui.value;
    ensureOverlay.value;
    killOld.value;
    ensureSynths.value;
    AppClock.sched(0.05, { mkBar.value; nil });
    nil
});
)
