// animateMetersWindowLayout_Grid_Minimal_DarkGreen.scd
// v1
// MD 20250930

(
// Attach + animate LevelIndicator meters in "Layout Test"
var win, collect, views;

views = List.new;
win = Window.allWindows.detect({ |w| w.name == "Layout Test" });

if(win.isNil) { "No window named 'Layout Test'.".warn; } {
    collect = { |v|
        views.add(v);
        v.children.do({ |c| collect.(c) });
    };
    collect.(win.view);
    ~meters = views.select({ |v| v.isKindOf(LevelIndicator) });

    // Start animation (single AppClock Routine)
    ~startMeters = {
        ~meterRoutine !? { ~meterRoutine.stop };
        ~meterRoutine = Routine({
            var t = 0.0;
            loop {
                var v1 = (sin(t * 0.30) * 0.5 + 0.5).clip(0, 1);
                var v2 = (sin(t * 0.21 + 1.1) * 0.5 + 0.5).clip(0, 1);
                ~meters.do({ |m, i| m.value_(i.even.if(v1, v2)) });
                t = t + 0.05;
                0.03.wait;  // ~33 fps
            }
        }).play(AppClock);
        "Meters animating…".postln;
    };

    // Stop animation
    ~stopMeters = {
        ~meterRoutine !? { ~meterRoutine.stop; ~meterRoutine = nil; "Meters stopped.".postln; };
    };

    "Found % meter(s). Use ~startMeters.() and ~stopMeters.().".format(~meters.size).postln;
};
)


/*
To use:

~startMeters.();
~stopMeters.();

*/