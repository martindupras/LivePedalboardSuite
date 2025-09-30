//////////////////////////////////////////////////////////////
// 00B_HUD_Force_GridDemo_Now.scd
// v0.1.0
// MD 20250929-13:02
/* Purpose
   - Close PerfHUD/GridDemo windows and bring up GridDemo (non-pulsing).
   - Assign ~gui to the GridDemo controller and bring it to front.
Style
   - var-first; AppClock UI; idempotent; no server.sync.
*/
(
var closeWindows, bringGrid, front;

closeWindows = {
    Window.allWindows
    .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
    .do(_.close);
};

bringGrid = {
    ~gui = MagicDisplayGUI_GridDemo.new;  // controller, not a Window
};

front = {
    if(~gui.respondsTo(\window)) {
        ~gui.window.front.alwaysOnTop_(true);
    };
    if(~gui.respondsTo(\showExpectation)) {
        ~gui.showExpectation("GridDemo ready (static A/B; no pulse)", 0);
    };
};

AppClock.sched(0.00, { closeWindows.value; nil });
AppClock.sched(0.05, { bringGrid.value; AppClock.sched(0.05, { front.value; nil }); nil });
)
