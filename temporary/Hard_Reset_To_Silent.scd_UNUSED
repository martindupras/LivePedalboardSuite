// Hard_Reset_To_Silent.scd
// v0.1.0
// MD 20251005-1157

/*
Purpose
- Wipe the server node tree, stop all NodeProxies, and recreate a silent baseline.
- Keeps style: var-first; no server.sync.
*/

(
var s;
s = Server.default;

// 0) protect: hard mute while we clean
s.volume.mute;

// 1) stop NodeProxies
Server.default.bind({
    // Stop common Ndefs if present
    [\testmelody, \ts0, \chainA, \chainB].do { |k|
        if(Ndef(k).notNil) { Ndef(k).stop };
    };
    // Optionally nuke all proxies (heavy-handed):
    // Ndef.clear;
});

// 2) wipe groups/synths and re-init tree
Server.default.bind({
    s.defaultGroup.freeAll;
    s.initTree; // rebuild default groups cleanly
});

// 3) re-materialize a silent 2ch "\ts0" and endpoints (not playing)
Server.default.bind({
    if(Ndef(\ts0).source.isNil) { Ndef(\ts0, { Silent.ar(2) }) };
    Ndef(\ts0).ar(2);
    if(Ndef(\chainA).notNil) { Ndef(\chainA).ar(2) };
    if(Ndef(\chainB).notNil) { Ndef(\chainB).ar(2) };
});

// 4) release hard mute
s.volume.unmute;

"🧹 Hard reset done: server tree wiped; 2ch silent baseline ready.".postln;
)