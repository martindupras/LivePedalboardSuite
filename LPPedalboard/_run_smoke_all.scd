/*
 LPPedalboard/_run_smoke_all.scd

 Single-file runner: execute the class file at top-level then run the smoke-play
 sequence. This allows invoking sclang with just this file as the argument.

 Usage (CLI):
 /Applications/SuperCollider.app/Contents/MacOS/sclang \
   "/path/to/LivePedalboardSuite/LPPedalboard/_run_smoke_all.scd"

 The script does three things:
  - run the class file text through the interpreter at top-level so classes are
    compiled/installed into the class library
  - run the smoke play sequence (boot server, create LPPedalboard, play/stop)
  - call thisProcess.interpreter.quit to exit cleanly
*/

// Attempt to instantiate and run the smoke sequence. Do NOT try to "execute"
// a class file here — classes must be compiled into the class library.
{
  var server, lp;
  try {
    server = Server.default;
    server.waitForBoot({ |s|
      lp = LPPedalboard.new; // requires LPPedalboard to be compiled/available
      lp.playCurrent;
      // schedule stop after 2 seconds and quit interpreter shortly after
      AppClock.sched(2.0, { lp.stopCurrent; });
      AppClock.sched(2.25, { thisProcess.interpreter.quit });
    });
  } { |err|
    // Likely the LPPedalboard class isn't available in the class library.
    "LPPedalboard class not available or instantiation failed: %".format(err).postln;
    "Please compile the class library (or load LPPedalboard.sc in the IDE) before running this runner.".postln;
    thisProcess.interpreter.quit;
  }
}.fork;
