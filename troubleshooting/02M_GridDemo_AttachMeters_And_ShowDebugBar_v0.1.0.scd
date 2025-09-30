// 02M_GridDemo_AttachMeters_And_ShowDebugBar.scd
// v0.1.0
// MD 20250929-1258

/* Purpose
   - Attach tiny A/B bus meters to your existing taps (A=2001, B=2002)
     so GridDemo can display a moving meter bar via its TestMeter extension.
   - Then show a small horizontal "debug meter" inside the right panel, driven by /ampA.
Style
   - var-first; AppClock UI; Server.default.bind for server ops; no server.sync; idempotent.
*/

(
var aBus, bBus, mkMeters, showBar, killOld, ensureGui;

aBus = 2001;  // from your tap step (see console)
bBus = 2002;  // from your tap step (see console)

/* 0) Ensure we have a GridDemo GUI controller (non-pulsing)
      If you prefer PerfHUD for this run, skip this ensure block.
*/
ensureGui = {
    if(~gui.isNil) {
        // keep only one MagicDisplayGUI window
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        ~gui = MagicDisplayGUI_GridDemo.new;
        if(~gui.respondsTo(\window)) { ~gui.window.front.alwaysOnTop_(true) };
    };
};

/* 1) Clean previous meter synths if we re-run */
killOld = {
    if(~meterA.notNil) { ~meterA.free; ~meterA = nil };
    if(~meterB.notNil) { ~meterB.free; ~meterB = nil };
};

/* 2) Create meter synths that publish /ampA and /ampB
      MagicDisplay already defines SynthDefs \busMeterA / \busMeterB (class init).
      We just need to instantiate them on our tap busses.
*/
mkMeters = {
    Server.default.bind({
        ~meterA = Synth(\busMeterA, [\inBus, aBus, \rate, 24]);  // → sends /ampA
        ~meterB = Synth(\busMeterB, [\inBus, bBus, \rate, 24]);  // → sends /ampB
    });
    "02M: A/B bus meters attached to 2001/2002.".postln;
};

/* 3) Show a small moving meter bar in GridDemo (right panel, near 'eff:')
      Uses GridDemo’s TestMeter extension (if present). Safe if absent.
*/
showBar = {
    if(~gui.notNil and: { ~gui.respondsTo(\testMeter_attach) }) {
        // show chain A level; change to \B to view next chain
        ~gui.testMeter_attach(\A);
        if(~gui.respondsTo(\showExpectation)) {
            ~gui.showExpectation("Debug meter (A) attached at 24 Hz", 0);
        };
    }{
        "02M: GridDemo TestMeter extension not found; no debug bar.".warn;
    };
};

ensureGui.value;
killOld.value;
mkMeters.value;
AppClock.sched(0.02, { showBar.value; nil });
)
