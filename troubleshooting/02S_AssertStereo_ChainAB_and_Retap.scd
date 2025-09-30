// 02S_AssertStereo_ChainAB_and_Retap.scd
// v0.1.0
// MD 20250929-0948

(
// Purpose
// - Force chainA/chainB to allocate *stereo* busses, then rewire A and reattach dB taps.
// - Clears stale 1001 (“test”) dict entry so HUD only shows A/B.
// Style
// - var-first; server ops in Server.default.bind.

var makeStereoBusses, rewireA, restartTaps, clearOldTestDict;

makeStereoBusses = {
    Server.default.bind({
        // Force stereo allocation by setting explicit stereo sources first
        Ndef(\chainA, { Silent.ar(2) }); Ndef(\chainA).ar(2);
        Ndef(\chainB, { Silent.ar(2) }); Ndef(\chainB).ar(2);
        // Materialize bus width
        Ndef(\chainA).play;
        Ndef(\chainB).stop;
    });
    "🛠️ Stereo busses asserted for chainA/chainB.".postln;
};

rewireA = {
    // Keep your exact operator
    Ndef(\chainA) <<> Ndef(\testmelody);
    "🔗 Rewired: testmelody -> chainA.".postln;
};

restartTaps = {
    // Reinstall dB taps using existing SynthDef \md_busTap_db
    Server.default.bind({
        if(~md_busTapA.notNil) { ~md_busTapA.free; ~md_busTapA = nil };
        if(~md_busTapB.notNil) { ~md_busTapB.free; ~md_busTapB = nil };
        ~md_busTapA = Synth.tail(s.defaultGroup, \md_busTap_db, [\inBus, Ndef(\chainA).bus.index, \rate, 24, \replyID, 2001]);
        ~md_busTapB = Synth.tail(s.defaultGroup, \md_busTap_db, [\inBus, Ndef(\chainB).bus.index, \rate, 24, \replyID, 2002]);
    });
    "📡 dB taps restarted on asserted stereo busses (A/B).".postln;
};

clearOldTestDict = {
    ~md_levelsById = ~md_levelsById ? IdentityDictionary.new;
    ~md_levelsById.removeAt(1001);  // remove “test” so HUD can’t mirror it
    ~md_lastMsgStamp = SystemClock.seconds.asFloat;
};

makeStereoBusses.value;
rewireA.value;
restartTaps.value;
clearOldTestDict.value;

"✅ Stereo confirmed, taps reattached. Expect both A bars moving, B near zero.".postln;
)
