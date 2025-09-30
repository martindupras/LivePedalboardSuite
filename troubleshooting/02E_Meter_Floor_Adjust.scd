// 02E_Meter_Floor_Adjust.scd
// v0.1.0
// MD 20250929-0912

(
// Purpose
// - Adjust the dB floor used by the md_busTap_db Synths on the fly.
// - Example sets floor to -48 dB (hotter visuals). Re-run with -60 to restore.
// Style
// - var-first; server ops in Server.default.bind.

var setFloorDB;

setFloorDB = { |floorDB = -48|
    Server.default.bind({
        if(~md_busTapA.notNil) { ~md_busTapA.set(\floorDB, floorDB) };
        if(~md_busTapB.notNil) { ~md_busTapB.set(\floorDB, floorDB) };
        if(~md_busTapT.notNil) { ~md_busTapT.set(\floorDB, floorDB) };
    });
    ("📏 Meter floor set to " ++ floorDB.asString ++ " dB").postln;
};

// Try -48 for a start, or -42 if you want it hotter:
setFloorDB.(-48);
)
