// MD_Taps_Clear_All.scd
// v0.1.0
// MD timestamp: 2025-09-28 10:45 GMT+1

/*
Purpose
- Remove any previously attached /md/levels taps on chainA/chainB/testmelody
  so only one producer drives A=2001 / B=2002.

Style
- Single () block; VAR-FIRST; no non-local returns; no server.sync.
*/

(
var cleared;

Server.default.bind({
    // Remove known tap filter keys if present
    Ndef(\chainA).filter(\eodTapA, nil);
    Ndef(\chainB).filter(\eodTapB, nil);
    Ndef(\testmelody).filter(\proofTap, nil);
});

cleared = "[TAPS] cleared filters: chainA(\\eodTapA), chainB(\\eodTapB), testmelody(\\proofTap)";
cleared.postln;
cleared
)
