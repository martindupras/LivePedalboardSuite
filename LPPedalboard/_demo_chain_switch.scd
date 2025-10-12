/*
 LPPedalboard Chain Switching Demo
 
 Minimal script to demonstrate:
 1. Instantiating LPPedalboard (which auto-creates test sources)
 2. Playing the current chain (starts with chainA + testmelodyA)
 3. Switching to the next chain (chainB + testmelodyB) with crossfade
 4. Switching back after a few seconds
 
 Usage: 
 1. First compile LPPedalboard.sc in the IDE (select all text, Cmd+Enter)
 2. Then run this script (select all text, Cmd+Enter)
*/

(
Server.default.waitForBoot({
    var lp;
    
    // Instantiate the pedalboard - this automatically:
    // - Creates chainA and chainB 
    // - Sets up testmelodyA and testmelodyB sources
    // - Connects chainA <<> testmelodyA and chainB <<> testmelodyB
    // - Sets currentChain = chainA, nextChain = chainB
    lp = LPPedalboard.new;
    
    "LPPedalboard created. Current chain should be playing testmelodyA...".postln;
    
    // The class auto-starts the current chain during init, but let's ensure it's playing
    lp.playCurrent;
    
    // Switch to next chain (chainB with testmelodyB) after 3 seconds
    AppClock.sched(3.0, {
        "Switching to next chain (testmelodyB)...".postln;
        lp.switchChain(0.15);  // 150ms crossfade
    });
    
    // Switch back after another 3 seconds
    AppClock.sched(6.0, {
        "Switching back to other chain...".postln;
        lp.switchChain(0.15);
    });
    
    // Stop after 9 seconds total
    AppClock.sched(9.0, {
        "Stopping current chain...".postln;
        lp.stopCurrent;
    });
});
)