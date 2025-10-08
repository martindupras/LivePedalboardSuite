// StepD_Switch_ToB.scd
// v0.0.1
// MD 20251008-1734

/* Purpose
- Stop B's silent tap (if running) to avoid duplicate meter events.
- Stop A sink and play B sink.
*/

(
var nothing;

Server.default.bind({
    if(Ndef(\lps_tapB).isPlaying) { Ndef(\lps_tapB).stop };
    Ndef(\chainA).stop;
    Ndef(\chainB).play;
});
nil
)