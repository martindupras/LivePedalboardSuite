// StepC_Play_AudibleA.scd
// v0.0.1
// MD 20251008-1734

/* Purpose
- Stop A's silent tap to avoid duplicate meter events, then play chainA and stop chainB.
- Result: A is audible; B silent.
*/

(
var nothing;

Server.default.bind({
    if(Ndef(\lps_tapA).isPlaying) { Ndef(\lps_tapA).stop };
    Ndef(\chainB).stop;
    Ndef(\chainA).play;
});
nil
)