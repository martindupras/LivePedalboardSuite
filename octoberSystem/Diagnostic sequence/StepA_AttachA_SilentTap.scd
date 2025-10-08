// StepA_AttachA_SilentTap.scd
// v0.0.1
// MD 20251008-1734

/* Purpose
- Map chainA input to \testmelodyA.
- Run a silent tap that reports /peakrmsA so the A-meter moves.
- No sink playback -> no audible output.
*/

(
var nothing;

// Map chainA to the A source (robust)
Server.default.bind({
    Ndef(\chainA).ar(2);
    Ndef(\chainA).map(\in, Ndef(\testmelodyA));
});

// Start a silent tap for A meters (no sound)
Server.default.bind({
    Ndef(\lps_tapA, {
        var inSig;
        inSig = \in.ar(0!2);
        SendPeakRMS.kr(inSig, 20, 3, '/peakrmsA', 42001);
        Silent.ar(2)  // ensures tap produces no audio
    });
    Ndef(\lps_tapA).map(\in, Ndef(\testmelodyA));  // tap the same source
    Ndef(\lps_tapA).play;  // pull the graph so meters update
});
nil
)
