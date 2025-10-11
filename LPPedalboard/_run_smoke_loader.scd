// Runner that first loads the LPPedalboard class file at top-level, then runs the smoke test.

var classPath = "/Users/martindupras/Library/CloudStorage/OneDrive-TheOpenUniversity/LivePedalboardSuite/LPPedalboard/LPPedalboard.sc";
thisProcess.interpreter.executeFile(classPath);
"LPPedalboard class executed (loaded)".postln;

(
    var lp;
    Server.default.waitForBoot({
        "Server booted".postln;
        lp = LPPedalboard.new(nil, nil);
        "Created LPPedalboard instance:"; lp.postln;
        "Playing current chain (expected: chain A) for 1 second".postln;
        lp.playCurrent;
        AppClock.sched(1.0, {
            lp.stopCurrent;
            "Stopped".postln;
            Server.default.quit;
            "Sent quit to server".postln;
            thisProcess.exit;
        });
    });
)
