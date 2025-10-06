// LP_AudioMute_Toggles.scd
// v0.1.0
// MD 20251006-1655

(
var installMute, clearMute;

("--LP_AudioMute_Toggles.scd").postln;

installMute = {
    Server.default.bind({
        Ndef(\chainA).filter(\audMute, { |in| in.isArray.if({ in*0 }, { [in, in]*0 }) });
        Ndef(\chainB).filter(\audMute, { |in| in.isArray.if({ in*0 }, { [in, in]*0 }) });
    });
    "[Audio] MUTE ON (post-meter)".postln;
};

clearMute = {
    Server.default.bind({
        Ndef(\chainA).clear(\audMute);
        Ndef(\chainB).clear(\audMute);
    });
    "[Audio] MUTE OFF".postln;
};

~muteAudio   = { installMute.() };
~unmuteAudio = { clearMute.() };
)