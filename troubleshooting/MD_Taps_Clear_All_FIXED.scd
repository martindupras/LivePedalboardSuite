// MD_Taps_Clear_All_FIXED.scd
// v0.1.1 (clear proxies instead of filter(..., nil))
// MD timestamp: 2025-09-28 10:52 GMT+1

/*
Purpose
- Remove all taps/filters by clearing proxies and recreating chainA as a 2‑ch audio proxy.

Style / Guard Rails
- Single () block; VAR-FIRST; no non-local returns; no server.sync.
*/

(
var msg;

Server.default.bind({
    // stop and clear any existing sources/filters/taps
    Ndef(\chainA).stop; Ndef(\chainA).clear; Ndef(\chainA).ar(2);
    Ndef(\chainB).stop; Ndef(\chainB).clear; Ndef(\chainB).ar(2);
    Ndef(\testmelody).stop; Ndef(\testmelody).clear;
});

msg = "[TAPS] cleared: chainA, chainB, testmelody — chainA re-created as 2ch.";
msg.postln;
msg
)
