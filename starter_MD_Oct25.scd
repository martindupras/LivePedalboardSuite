// starter_MD_Oct25.scd
// v0.5.5

// Start an LPOrchestrator
//   it starts server, then creates lpDisplay, logger, commandManager and pedalboard internals:
~orchestrator = LPOrchestrator.new();
// window should open

//DEBUG
//~orchestrator.lpDisplay.postln;


// tests

~orchestrator.check; //passes
~orchestrator.pedalboard.check; //passes
~orchestrator.pedalboard.theChain; // passes

~orchestrator.pedalboard.theChain.insertTest("bob"); // works

~orchestrator.pedalboard.theChain.insertPassthrough("rita"); // works

~orchestrator.pedalboard.theChain.insert("libPassthrough"); // found but makes chain silent. WHY?


//new
~orchestrator.pedalboard.testInputSignalBeOn;  // works v1.1.13.1
~orchestrator.pedalboard.testInputSignalBeOff; // works v.1.1.13.1

~orchestrator.pedalboard.theChain.remove(); // works

~orchestrator.pedalboard.theChain.insert("tremolo"); // not found in library - passing a string


~orchestrator.pedalboard.theChain.insert(\libPassthrough); // try
~orchestrator.pedalboard.theChain.remove(); // works

// new v 0.4.7.8
~orchestrator.pedalboard.theChain.insert(\tremolo); // try

~orchestrator.pedalboard.theChain.insert(\delay); // try

~orchestrator.printDiagMessages("be-bop a lula"); // works now




//THIS WORKS
~orchestrator.pedalboard.display.sendPaneText(\left, "REACHED LEFT PANE");


// SANITY CHECKS
// these work though...
/*
~testDisplay = LPDisplay.new();
~testDisplay.sendPaneText(\diag, '12343254645'); // works
~testDisplay.sendPaneText(\diag, "ertwertyu");   // works
*/








/*
// Now put a test source into input of pedalboard
Ndef(\pulseNoise, {SinOsc.ar(freq:3, mul: { PinkNoise.ar(0.1!2)})});

//check that it works:
Ndef(\pulseNoise).play;

// it does. Turn it off.
Ndef(\pulseNoise).stop;
*/
