// MD_Cleanup_ChainA_Unfeed.scd
// v0.1.0
// MD timestamp: 2025-09-27 19:58 GMT+1

/*
Purpose
- Stop audio; clear and recreate Ndef(\chainA) so the pedalboard can drive it again.
*/

(
var done;
Server.default.bind({
    Ndef(\chainA).stop;
    Ndef(\chainA).clear;
    Ndef(\chainA).ar(2);
});
done = "Cleaned chainA—pedalboard can drive it again.";
done.postln;
done
)
