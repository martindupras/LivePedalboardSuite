// Test_LPOrchestrator_Minimal_NoDisplay.scd
// v1.0.0
// MD 20251011-1738

(
var orch, lpb;

orch = LPOrchestrator.new;

AppClock.sched(2.5, {  // wait for postServerInit (~2 s)
    lpb = orch.pedalboard;

    lpb.setDisplay(nil);             // <<< minimal fix: avoid display callback DNU
    lpb.setSourcesBoth(\testmelodyA); // choose an audible source
    lpb.playCurrent;                  // start audio to hardware out

    "Chain A should now be audible.".postln;
});
)