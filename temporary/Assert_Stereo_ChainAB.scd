// Assert_Stereo_ChainAB.scd
// v0.1.0
// MD 20251006-1702

(
Server.default.bind({
    if (Ndef(\chainA).numChannels != 2) { Ndef(\chainA).ar(2) };
    if (Ndef(\chainB).numChannels != 2) { Ndef(\chainB).ar(2) };
    // defensive: ensure post-meter forceStereo (no audible change while muted)
    Ndef(\chainA).filter(\forceStereo, { |in| in.isArray.if({ in }, { [in, in] }) });
    Ndef(\chainB).filter(\forceStereo, { |in| in.isArray.if({ in }, { [in, in] }) });
});
"asserted chainA/B to stereo buses".postln;
)
