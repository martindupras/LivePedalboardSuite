// 02B_HUD_Receiver_dB_Map.scd
// v0.1.1
// MD 20250928-2050

(
// Purpose
// - Reinstall the HUD OSCdef to read the *linear* bus taps from "/md/levels_bus"
//   and convert them to a log/decibel-like visual scale on the *language* side.
// - No UGens here; only language methods (known-good): .ampdb, .max, arithmetic.
// - Mapping: floor = -60 dB -> 0.0, 0 dB -> 1.0 (adjust floor as needed).
// Style
// - var-first; no server.sync; UI/OSC on language side; no non-local returns.

var key, minDB, mapToMeter;

// ---- settings ----
key   = \md_levels_hud;  // the same key PerfHUD expects
minDB = -60.0;           // raise to -48 or -42 if you want hotter-looking bars

// ---- mapping function (language side) ----
mapToMeter = { |amp|
    var db, v;
    // guard tiny values to avoid -inf
    db = amp.max(1e-9).ampdb;    // amp -> dB (language method)
    db = db.max(minDB);          // clamp floor
    // map -60..0 dB -> 0..1
    v = (db - minDB) / (0 - minDB);
    v.clip(0, 1)
};

// ---- reinstall the OSCdef safely ----
if(OSCdef.all.at(key).notNil) { OSCdef(key).free };

~md_levelsById   = ~md_levelsById ? IdentityDictionary.new;
~md_lastMsgStamp = SystemClock.seconds.asFloat;

OSCdef(key, { |msg|
    // SendReply -> msg[0]=path, msg[1]=nodeID, msg[2]=replyID, msg[3]=L, msg[4]=R
    var id, lAmp, rAmp, l, r;
    if(msg.size >= 5) {
        id   = msg[2].asInteger;
        lAmp = msg[3].asFloat;
        rAmp = msg[4].asFloat;
        l = mapToMeter.(lAmp);
        r = mapToMeter.(rAmp);
        ~md_levelsById.put(id, [l, r]);
        ~md_lastMsgStamp = SystemClock.seconds.asFloat;
    };
    nil
}, "/md/levels_bus", recvPort: NetAddr.langPort);

("[HUD] md_levels_hud reinstalled (dB map; floor = " ++ minDB.asString ++ " dB)").postln;
)
