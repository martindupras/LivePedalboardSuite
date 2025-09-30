// 02B_Taps_dB_NoTest_and_HUD.scd
// v0.1.0
// MD 20250929-0918

(
// Purpose
// - Install server-side dB-mapped taps for Chain A and Chain B only (no "test").
// - Reinstall the HUD receiver to read "/md/levels_bus" and update dict keys:
//   2001 (A) and 2002 (B).
// Style
// - var-first; no server.sync; Server.default.bind; known-good UGens only.

var minDB, makeTapDefOnce, installBusTaps_dB_AB, installHudReceiver_AB, aBus, bBus;
minDB = -60;  // try -48 for hotter visuals

makeTapDefOnce = {
    SynthDef(\md_busTap_db, { |inBus=0, rate=24, replyID=2001, floorDB = -60|
        var sig, aL, aR, dbL, dbR, vL, vR, ln10;
        sig = In.ar(inBus, 2);
        aL  = Amplitude.kr(sig[0], 0.01, 0.20).max(1e-9);
        aR  = Amplitude.kr(sig[1], 0.01, 0.20).max(1e-9);
        ln10 = 2.302585092994046; // constant
        dbL = 20 * (log(aL) / ln10);
        dbR = 20 * (log(aR) / ln10);
        dbL = max(dbL, floorDB);
        dbR = max(dbR, floorDB);
        vL  = (dbL - floorDB) / (0 - floorDB);
        vR  = (dbR - floorDB) / (0 - floorDB);
        vL  = LagUD.kr(vL.clip(0,1), 0.02, 0.12);
        vR  = LagUD.kr(vR.clip(0,1), 0.02, 0.12);
        SendReply.kr(Impulse.kr(rate), "/md/levels_bus", [vL, vR], replyID);
    }).add;
    "🔧 SynthDef \\md_busTap_db installed (server-side dB mapping).".postln;
};

installBusTaps_dB_AB = {
    Server.default.bind({
        aBus = Ndef(\chainA).bus.index;
        bBus = Ndef(\chainB).bus.index;

        if(~md_busTapA.notNil) { ~md_busTapA.free; ~md_busTapA = nil };
        if(~md_busTapB.notNil) { ~md_busTapB.free; ~md_busTapB = nil };

        ~md_busTapA = Synth.tail(s.defaultGroup, \md_busTap_db, [\inBus, aBus, \rate, 24, \replyID, 2001, \floorDB, minDB]);
        ~md_busTapB = Synth.tail(s.defaultGroup, \md_busTap_db, [\inBus, bBus, \rate, 24, \replyID, 2002, \floorDB, minDB]);
        "📡 Bus taps (dB) active for A/B only (floor=" ++ minDB.asString ++ " dB).".postln;
    });
};

installHudReceiver_AB = {
    var key;
    key = \md_levels_hud;
    if(OSCdef.all.at(key).notNil) { OSCdef(key).free };

    ~md_levelsById   = ~md_levelsById ? IdentityDictionary.new;
    ~md_lastMsgStamp = SystemClock.seconds.asFloat;

    OSCdef(key, { |msg|
        // SendReply => [ path, nodeID, replyID, L, R ]
        var id, l, r;
        if(msg.size >= 5) {
            id = msg[2].asInteger;          // 2001 or 2002
            if((id == 2001) or: { id == 2002 }) {
                l = msg[3].asFloat.clip(0,1);
                r = msg[4].asFloat.clip(0,1);
                ~md_levelsById.put(id, [l, r]);
                ~md_lastMsgStamp = SystemClock.seconds.asFloat;
            };
        };
        nil
    }, "/md/levels_bus", recvPort: NetAddr.langPort);

    "[HUD] md_levels_hud listening on /md/levels_bus (A/B only).".postln;
};

makeTapDefOnce.value;
installBusTaps_dB_AB.value;
installHudReceiver_AB.value;
"✅ dB taps installed and HUD receiver set (A=2001, B=2002).".postln;
)
