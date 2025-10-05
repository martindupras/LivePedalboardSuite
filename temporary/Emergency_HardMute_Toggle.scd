// Emergency_HardMute_Toggle.scd
// v0.1.0
// MD 20251005-1152

/*
Purpose
- Absolute, immediate audio kill at the server level (not dependent on your graph).
- Provides two helpers:
  • ~hardMute_on  -> mutes the server master and installs a tail ReplaceOut silencer.
  • ~hardMute_off -> restores volume and removes the silencer.
Style
- var-first; lowercase; no server.sync; Server.default.bind for graph ops.
*/

(
// --- vars
var s, ensureDefs, installSilencer, removeSilencer;

s = Server.default;

ensureDefs = {
    SynthDef(\__lpsHardMute2ch, {
        // Replace whatever reached hardware out 0/1 with silence.
        ReplaceOut.ar(0, Silent.ar(2));
    }).add;
};

installSilencer = {
    ensureDefs.();
    // Add the silencer synth at the tail so it runs after most nodes.
    // (Even if other nodes appear later, master volume mute below guarantees silence.)
    ~lps_hardMuteSynth = Synth.tail(s, \__lpsHardMute2ch);
    "🔇 Installed tail ReplaceOut silencer on out 0/1.".postln;
};

removeSilencer = {
    if(~lps_hardMuteSynth.notNil) {
        ~lps_hardMuteSynth.free; ~lps_hardMuteSynth = nil;
        "✅ Removed ReplaceOut silencer.".postln;
    };
};

// --- public helpers
~hardMute_on = {
    // 1) server master volume: mute immediately
    s.volume.mute;            // hard, global
    // 2) tail silencer: belt-and-braces
    Server.default.bind({ installSilencer.() });
    "🛑 HARD MUTE: server volume muted and tail silencer installed.".postln;
};

~hardMute_off = {
    // 1) remove silencer synth
    Server.default.bind({ removeSilencer.() });
    // 2) restore volume to unity
    s.volume.unmute;          // or: s.volume.db = 0;
    "▶️ HARD MUTE OFF: server volume restored and silencer removed.".postln;
};

"Emergency hard-mute helpers ready: ~hardMute_on.( ) / ~hardMute_off.( )".postln;
)