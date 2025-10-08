// StepB_AttachB_SilentTap.scd
// v0.0.1
// MD 20251008-1734

/* Purpose
- Map chainB input to \testmelodyB.
- Run a silent tap that reports /peakrmsB so the B-meter moves.
- No sink playback -> no audible output.
*/

(
var nothing;

Server.default.bind({
    Ndef(\chainB).ar(2);
    Ndef(\chainB).map(\in, Ndef(\testmelodyB));
});

Server.default.bind({
    Ndef(\lps_tapB, {
        var inSig;
        inSig = \in.ar(0!2);
        SendPeakRMS.kr(inSig, 20, 3, '/peakrmsB', 42002);
        Silent.ar(2)
    });
    Ndef(\lps_tapB).map(\in, Ndef(\testmelodyB));
    Ndef(\lps_tapB).play;
});
nil
)