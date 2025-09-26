// Sim_MIDI_FootAndGuitar_Demo_v0.1.scd
// v0.1.2
// MD 2025-09-26 10:45 BST

/* Purpose / Style
   Simulate foot controller + hex guitar without hardware:
   - FOOT (noteOn): 36→\idle, 38→\prog, 40→\queue, 41→\send
   - GUITAR (channels 0..5 → strings 6..1) bases [40,45,50,55,59,64]
   - Drives MIDIInputManager handlers + CommandManager + adapter bridge if present.

   Style
   - var-first everywhere; descriptive lowercase variable names; AppClock-only; no server.sync.
   - Generated audio only; exclusivity Option A remains enforced by bring-up (no SoundIn).
*/

(
var ensureSystem, basePitches, ensureReady, footToIdle, footToProg, footToQueue, footToSend;
var guitarNote, navFret, showCanonical, refreshChoices;
var runScenarioAddDelay, runScenarioSwitch, runScenarioBypassOn, runAllScenarios, logger;

logger = { arg message; ("[SIM] " ++ message).postln };

ensureSystem = {
    var systemInstance;
    if(~system.notNil and: { ~system.respondsTo(\shutdownAll) }) { ~system.shutdownAll };
    systemInstance = LivePedalboardSystem.new(nil);  // nil -> class path resolver
    ~system = systemInstance;
    ~system.bringUpAll;
    if(~system.respondsTo(\installAdapterBridge)) { ~system.installAdapterBridge };
    logger.("system is up (GUI + MPB + CommandTree)");
};

ensureReady = {
    var ok;
    ok = ~system.notNil
        and: { ~system.commandManager.notNil }
        and: { ~system.commandManager.midiManager.notNil };
    if(ok.not) { "⚠️ Run ensureSystem.() first".warn };
    ok
};

basePitches = IdentityDictionary[
    0 -> 40, 1 -> 45, 2 -> 50, 3 -> 55, 4 -> 59, 5 -> 64
];

footToIdle  = { if(ensureReady.()) { ~system.commandManager.midiManager.footControllerHandler.handleMessage(0, \noteOn, 36) } };
footToProg  = { if(ensureReady.()) { ~system.commandManager.midiManager.footControllerHandler.handleMessage(0, \noteOn, 38) } };
footToQueue = { if(ensureReady.()) { ~system.commandManager.midiManager.footControllerHandler.handleMessage(0, \noteOn, 40) } };
footToSend  = { if(ensureReady.()) { ~system.commandManager.midiManager.footControllerHandler.handleMessage(0, \noteOn, 41) } };

guitarNote = { arg stringNumber, fretNumber;
    var midiManager, channelIndex, baseNote, midiPitch;
    if(ensureReady.().not) { ^nil };
    midiManager = ~system.commandManager.midiManager;
    channelIndex = (6 - stringNumber.asInteger).clip(0, 5);
    baseNote = basePitches[channelIndex];
    if(baseNote.isNil) { "⚠️ Invalid string number".warn; ^nil };
    midiPitch = (baseNote + fretNumber.asInteger).asInteger;
    midiManager.guitarHandler.handleMessage(channelIndex, \noteOn, midiPitch);
};
navFret = { arg stringNumber, fretNumber; guitarNote.(stringNumber, fretNumber) };

showCanonical = {
    var cmRef, builderRef, longPath, shortPath;
    if(ensureReady.().not) { ^nil };
    cmRef = ~system.commandManager; builderRef = cmRef.builder;
    builderRef.printPathToRoot;
    longPath  = cmRef.buildLongPathFromBuilder(builderRef);
    shortPath = cmRef.canonicalPathFromBuilder(builderRef);
    ("• long=" ++ longPath ++ "  canonical=" ++ shortPath).postln;
};
refreshChoices = { if(~system.notNil) { ~system.commandManager.updateDisplay } };

runScenarioAddDelay = {
    footToProg.(); refreshChoices.();
    navFret.(6, 1); navFret.(5, 5); navFret.(4, 3);
    showCanonical.(); footToQueue.(); footToSend.();
    logger.("Scenario A complete (add delay)");
};

runScenarioSwitch = {
    footToProg.();
    navFret.(6, 5);
    showCanonical.(); footToQueue.(); footToSend.();
    logger.("Scenario B complete (switch)");
};

runScenarioBypassOn = {
    footToProg.();
    navFret.(6, 3); navFret.(5, 9); navFret.(4, 3); navFret.(3, 3);
    showCanonical.(); footToQueue.(); footToSend.();
    logger.("Scenario C complete (bypass delay on)");
};

runAllScenarios = {
    var stepIndex;
    stepIndex = 0;
    AppClock.sched(0.0, {
        switch(stepIndex,
            0, { ensureSystem.(); stepIndex = 1; AppClock.sched(0.40, { runAllScenarios.(); nil }) },
            1, { runScenarioAddDelay.(); stepIndex = 2; AppClock.sched(0.80, { runAllScenarios.(); nil }) },
            2, { runScenarioSwitch.();   stepIndex = 3; AppClock.sched(0.80, { runAllScenarios.(); nil }) },
            3, { runScenarioBypassOn.(); nil },
            { nil }
        );
        nil
    });
    "[SIM] queued runAllScenarios".postln;
};

~sim_runAll = { runAllScenarios.() };
logger.("Evaluate:  ensureSystem.();  then  ~sim_runAll.();");
)
