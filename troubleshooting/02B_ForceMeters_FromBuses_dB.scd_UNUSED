// 02B_ForceMeters_FromBuses_dB.scd
// v0.1.2
// MD 20250929-0838

(
// Purpose
// - Replace bus taps with server-side dB-mapped meters (−60 dB -> 0.0, 0 dB -> 1.0).
// - Keep using the existing /md/levels_bus receiver (ids: 2001=A, 2002=B, 1001=test).
// Style
// - var-first; no server.sync; Server.default.bind; known-good UGens only.

var minDB, makeTapDefOnce, replaceBusTaps_dB, aBus, bBus, tBus;

minDB = -60;  // raise to -48 or -42 if you want hotter bars

makeTapDefOnce = {
    SynthDef(\md_busTap_db, { |inBus=0, rate=24, replyID=2001, floorDB = -60|
        var sig, aL, aR, dbL, dbR, vL, vR, ln10;
        sig = In.ar(inBus, 2);
        aL  = Amplitude.kr(sig[0], 0.01, 0.20).max(1e-9);  // avoid -inf
        aR  = Amplitude.kr(sig[1], 0.01, 0.20).max(1e-9);
        ln10 = 2.302585092994046;                           // constant
        dbL = 20 * (log(aL) / ln10);
        dbR = 20 * (log(aR) / ln10);
        dbL = max(dbL, floorDB);                            // clamp to floor
        dbR = max(dbR, floorDB);
        vL  = (dbL - floorDB) / (0 - floorDB);              // map -60..0 -> 0..1
        vR  = (dbR - floorDB) / (0 - floorDB);
        vL  = LagUD.kr(vL.clip(0,1), 0.02, 0.12);           // gentle smoothing
        vR  = LagUD.kr(vR.clip(0,1), 0.02, 0.12);
        SendReply.kr(Impulse.kr(rate), "/md/levels_bus", [vL, vR], replyID);
    }).add;
    "🔧 SynthDef \\md_busTap_db installed (server-side dB mapping).".postln;
};

replaceBusTaps_dB = {
    Server.default.bind({
        aBus = Ndef(\chainA).bus.index;
        bBus = Ndef(\chainB).bus.index;
        tBus = Ndef(\testmelody).bus.index;

        if(~md_busTapA.notNil) { ~md_busTapA.free; ~md_busTapA = nil };
        if(~md_busTapB.notNil) { ~md_busTapB.free; ~md_busTapB = nil };
        if(~md_busTapT.notNil) { ~md_busTapT.free; ~md_busTapT = nil };

        ~md_busTapA = Synth.tail(s.defaultGroup, \md_busTap_db, [\inBus, aBus, \rate, 24, \replyID, 2001, \floorDB, minDB]);
        ~md_busTapB = Synth.tail(s.defaultGroup, \md_busTap_db, [\inBus, bBus, \rate, 24, \replyID, 2002, \floorDB, minDB]);
        ~md_busTapT = Synth.tail(s.defaultGroup, \md_busTap_db, [\inBus, tBus, \rate, 24, \replyID, 1001, \floorDB, minDB]);
    });
    ("📡 Bus taps replaced with dB mapping (floor = " ++ minDB.asString ++ " dB).").postln;
};

makeTapDefOnce.value;
replaceBusTaps_dB.value;
"✅ 02B dB taps active; HUD continues on /md/levels_bus (md_levels_hud).".postln;
)
