// MagicDisplayGUI_PerfHUD_MeterResponders_Ext.scd
// v0.1.0
// MD 2025-09-26 15:36 BST

/* Purpose
   Install language-side responders for /ampA and /ampB so that, even when
   AutoMeters emits those paths (instead of /md/levels), we keep populating
   ~md_levelsById (A=2001, B=2002) used by PerfHUD meters.
   - var-first; descriptive lowercase; AppClock-only; no server.sync.
*/

(

	//new
	var ensureAmpRespondersInstalled;
var installHudMeterMappingHelpers;


~md_installAmpToModelResponders = {
    var ensureModel, existingA, existingB;




    ensureModel = {
        ~md_levelsById   = ~md_levelsById   ? IdentityDictionary.new;
        ~md_lastMsgStamp = ~md_lastMsgStamp ? SystemClock.seconds.asFloat;
        nil
    };
    ensureModel.();

    // /ampA -> model[2001]
    existingA = OSCdef.all.at(\ampA_to_model);
    if(existingA.notNil) { existingA.free };
    OSCdef(\ampA_to_model, { arg msg;
        var leftVal, rightVal;
        leftVal  = (msg.size >= 4).if({ msg[3] }, { 0 }).asFloat.clip(0, 1);
        rightVal = (msg.size >= 5).if({ msg[4] }, { 0 }).asFloat.clip(0, 1);
        ~md_levelsById.put(2001, [leftVal, rightVal]);
        ~md_lastMsgStamp = SystemClock.seconds.asFloat;
        nil
    }, "/ampA", recvPort: NetAddr.langPort);

    // /ampB -> model[2002]
    existingB = OSCdef.all.at(\ampB_to_model);
    if(existingB.notNil) { existingB.free };
    OSCdef(\ampB_to_model, { arg msg;
        var leftVal, rightVal;
        leftVal  = (msg.size >= 4).if({ msg[3] }, { 0 }).asFloat.clip(0, 1);
        rightVal = (msg.size >= 5).if({ msg[4] }, { 0 }).asFloat.clip(0, 1);
        ~md_levelsById.put(2002, [leftVal, rightVal]);
        ~md_lastMsgStamp = SystemClock.seconds.asFloat;
        nil
    }, "/ampB", recvPort: NetAddr.langPort);

    "[HUD] ampA/ampB responders installed -> ~md_levelsById".postln;
    nil
};


ensureAmpRespondersInstalled = {
    var hasAmpA, hasAmpB;

    hasAmpA = OSCdef.all.at(\ampA_to_model).notNil;
    hasAmpB = OSCdef.all.at(\ampB_to_model).notNil;

    if(hasAmpA.not or: { hasAmpB.not }) {
        (~md_installAmpToModelResponders ? { nil }).value;
        "[HUD] ensured ampA/ampB responders installed.".postln;
    };
    nil
};

installHudMeterMappingHelpers = {
    // Display calibration (keeper defaults; tweak to taste)
    ~hud_meter_floor_db = ~hud_meter_floor_db ? -60.0; // visual floor
    ~hud_meter_top_db   = ~hud_meter_top_db   ? -6.0;  // headroom so typical peaks don't peg
    ~hud_meter_gamma    = ~hud_meter_gamma    ? 1.0;   // 1.0=linear; <1 raises lows; >1 tames lows

    // Linear (0..1) → UI value (0..1) with dB headroom and optional curve
    ~hud_map_linear_to_ui = { arg linearValue;
        var dbValue, normalizedValue, curvedValue, floorDb, topDb, gammaValue;
        floorDb    = ~hud_meter_floor_db;
        topDb      = ~hud_meter_top_db;
        gammaValue = ~hud_meter_gamma;

        dbValue = (max(linearValue, 1e-7)).log10 * 20.0;             // linear → dB
        normalizedValue = dbValue.linlin(floorDb, topDb, 0.0, 1.0);  // dB → 0..1 (with top < 0 dBFS)
        normalizedValue = normalizedValue.clip(0.0, 1.0);
        curvedValue = normalizedValue.pow(gammaValue);                // perceptual shaping (optional)
        curvedValue
    };

    "[HUD] meter mapping helpers installed (floor/top/gamma)".postln;
    nil
};

AppClock.sched(0.0, { ensureAmpRespondersInstalled.(); nil });
AppClock.sched(0.0, { installHudMeterMappingHelpers.(); nil });

)
