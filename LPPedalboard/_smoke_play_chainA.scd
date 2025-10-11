(
// Simple smoke test for LPPedalboard: boot server, load class, instantiate, play current chain A briefly.

var proj = "/Users/martindupras/Library/CloudStorage/OneDrive-TheOpenUniversity/LivePedalboardSuite";
var f, txt;

// helper to read & interpret file safely (single-call form)
// Check whether the LPPedalboard class is already loaded in this interpreter
var classLoaded = true;
// try {
// 	LPPedalboard.class; // if undefined, this will throw and be caught
// } { |err|
// 	classLoaded = false;
// 	"LPPedalboard class not found in current interpreter.".postln;
// 	"Please load LPPedalboard/LPPedalboard.sc first, or run sclang with the class file as the first argument:" .postln;
// 	"/Applications/SuperCollider.app/Contents/MacOS/sclang \"<path-to>/LPPedalboard/LPPedalboard.sc\" \"<path-to>/LPPedalboard/_smoke_play_chainA.scd\"".postln;
// }
//
// if(classLoaded.not) { ^thisProcess.exit; }

"Starting server (s.boot)".postln;
Server.default.waitForBoot({
    var lp;
    "Server booted".postln;

    // create a LPPedalboard instance (no display, no processorLib)
    lp = LPPedalboard.new(nil, nil);
    "Created LPPedalboard instance:"; lp.postln;

    // play current chain (should be chain A by default)
    "Playing current chain (expected: chain A) for 1 second".postln;
    lp.playCurrent;

    // stop after 1 second
    AppClock.sched(1.0, {
        lp.stopCurrent;
        "Stopped".postln;
        // cleanup: quit server
        Server.default.quit;
        "Sent quit to server".postln;
        // ensure the interpreter quits when the server quit message was sent
        thisProcess.interpreter.quit;
    });
});
)