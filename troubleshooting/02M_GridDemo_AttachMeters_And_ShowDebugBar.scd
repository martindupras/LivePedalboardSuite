//////////////////////////////////////////////////////////////
// 02M_GridDemo_AttachMeters_And_ShowDebugBar.scd
// v0.1.1
// MD 20250929-13:02
/* Purpose
   - Attach meter Synths to tap busses (A=2001, B=2002), emitting /ampA,/ampB.
//  - Display a small moving bar inside GridDemo (right panel) via TestMeter ext.
Style
   - var-first; Server.default.bind for synths; AppClock for UI; no server.sync.
*/

(
var aBus, bBus, mkMeters, stopOld, showBar, ensure;

aBus = 2001;  bBus = 2002;

ensure = {
    if(~gui.isNil) {
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        ~gui = MagicDisplayGUI_GridDemo.new;
        if(~gui.respondsTo(\window)) { ~gui.window.front.alwaysOnTop_(true) };
    };
};

stopOld = {
    if(~meterA.notNil) { ~meterA.free; ~meterA = nil };
    if(~meterB.notNil) { ~meterB.free; ~meterB = nil };
};

mkMeters = {
    Server.default.bind({
        ~meterA = Synth(\busMeterA, [\inBus, aBus, \rate, 24]);  // → /ampA
        ~meterB = Synth(\busMeterB, [\inBus, bBus, \rate, 24]);  // → /ampB
    });
    "02M: A/B bus meters attached to 2001/2002.".postln;
};

showBar = {
    if(~gui.respondsTo(\testMeter_attach)) {
        ~gui.testMeter_attach(\A);   // or \B to view NEXT
        if(~gui.respondsTo(\showExpectation)) {
            ~gui.showExpectation("Debug meter (A) attached at 24 Hz", 0);
        };
    }{
        "02M: GridDemo TestMeter extension not found; no debug bar.".warn;
    };
};

ensure.value;
stopOld.value;
mkMeters.value;
AppClock.sched(0.02, { showBar.value; nil });
)
