// starter_MD_Oct25.scd
// v0.5.1

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

~orchestrator.check; //fails
~orchestrator.pedalboard.check; //passes
~orchestrator.pedalboard.theChain; // passes

~orchestrator.pedalboard.theChain.insertTest("bob"); // works but no decrease in amplitude

~orchestrator.printDiagMessages("well hello there");