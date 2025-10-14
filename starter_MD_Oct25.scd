// starter_MD_Oct25.scd
// v0.5.2

// Start an LPOrchestrator
//   it starts server, then creates lpDisplay, logger, commandManager and pedalboard internals:
~orchestrator = LPOrchestrator.new();
// window should open


/*
// Now put a test source into input of pedalboard
Ndef(\pulseNoise, {SinOsc.ar(freq:3, mul: { PinkNoise.ar(0.1!2)})});

//check that it works:
Ndef(\pulseNoise).play;

// it does. Turn it off.
Ndef(\pulseNoise).stop;
*/



// tests

~orchestrator.check; //passes
~orchestrator.pedalboard.check; //passes
~orchestrator.pedalboard.theChain; // passes

~orchestrator.pedalboard.theChain.insertTest("bob"); // works but no decrease in amplitude

~orchestrator.printDiagMessages("well hello there"); // QUESTION doesn't display...


// these work though...
~testDisplay = LPDisplay.new();
~testDisplay.sendPaneText(\diag, '12343254645'); // works
~testDisplay.sendPaneText(\diag, "ertwertyu");   // works



~orchestrator.lpDisplay.postln;
