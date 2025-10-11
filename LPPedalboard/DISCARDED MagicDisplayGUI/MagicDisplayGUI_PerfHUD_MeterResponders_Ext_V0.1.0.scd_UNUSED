// MagicDisplayGUI_PerfHUD_MeterResponders_Ext.scd
// v0.1.1
// MD 2025-09-29 16:58 BST

/* Purpose
   Install language-side OSC responders for /ampA and /ampB so that, even when
   AutoMeters emits those paths (instead of /md/levels), we keep populating
   ~md_levelsById (A=2001, B=2002) used by PerfHUD meters. Also install HUD
   meter mapping helpers so UI levels have headroom and do not peg at 1.0.

   Keeper notes
   - 2025-09-29: Ensure ampA/ampB responders auto-install on HUD bring-up (after reset).
                 Added ~hud_map_linear_to_ui (and dB sibling) with defaults:
                 floor -60 dB, top -6 dB, gamma 1.0. Apply at UI write-site.
                 Without responders, ~md_levelsById may be stale/empty → solid green meters.

Style
   - var-first; descriptive lowercase names; AppClock-only for UI; no server.sync; no non-local returns.
*/

(
var ensureAmpRespondersInstalled, installHudMeterMappingHelpers;

~md_installAmpToModelResponders = {
    var ensureModelReady, existingResponderA, existingResponderB;

    ensureModelReady = {
        ~md_levelsById   = ~md_levelsById   ? IdentityDictionary.new;
        ~md_lastMsgStamp = ~md_lastMsgStamp ? SystemClock.seconds.asFloat;
        nil
    };
    ensureModelReady.();

    // /ampA -> model[2001]
    existingResponderA = OSCdef.all.at(\ampA_to_model);
    if(existingResponderA.notNil) { existingResponderA.free };
    OSCdef(\ampA_to_model, { arg oscMessage;
        var leftLinear, rightLinear;
        leftLinear  = (oscMessage.size >= 4).if({ oscMessage[3] }, { 0.0 }).asFloat.clip(0.0, 1.0);
        rightLinear = (oscMessage.size >= 5).if({ oscMessage[4] }, { 0.0 }).asFloat.clip(0.0, 1.0);
        ~md_levelsById.put(2001, [leftLinear, rightLinear]);
        ~md_lastMsgStamp = SystemClock.seconds.asFloat;
        nil
    }, "/ampA", recvPort: NetAddr.langPort);

    // /ampB -> model[2002]
    existingResponderB = OSCdef.all.at(\ampB_to_model);
    if(existingResponderB.notNil) { existingResponderB.free };
    OSCdef(\ampB_to_model, { arg oscMessage;
        var leftLinear, rightLinear;
        leftLinear  = (oscMessage.size >= 4).if({ oscMessage[3] }, { 0.0 }).asFloat.clip(0.0, 1.0);
        rightLinear = (oscMessage.size >= 5).if({ oscMessage[4] }, { 0.0 }).asFloat.clip(0.0, 1.0);
        ~md_levelsById.put(2002, [leftLinear, rightLinear]);
        ~md_lastMsgStamp = SystemClock.seconds.asFloat;
        nil
    }, "/ampB", recvPort: NetAddr.langPort);

    "[HUD] ampA/ampB responders installed -> ~md_levelsById".postln;
    nil
};

ensureAmpRespondersInstalled = {
    var hasResponderA, hasResponderB;
    hasResponderA = OSCdef.all.at(\ampA_to_model).notNil;
    hasResponderB = OSCdef.all.at(\ampB_to_model).notNil;

    if(hasResponderA.not or: { hasResponderB.not }) {
        (~md_installAmpToModelResponders ? { nil }).value;
        "[HUD] ensured ampA/ampB responders installed.".postln;
    };
    nil
};

installHudMeterMappingHelpers = {
    // Keeper defaults (adjust to taste across sessions)
    ~hud_meter_floor_db = ~hud_meter_floor_db ? -60.0; // visual floor
    ~hud_meter_top_db   = ~hud_meter_top_db   ? -6.0;  // headroom so typical peaks don't peg
    ~hud_meter_gamma    = ~hud_meter_gamma    ? 1.0;   // 1.0=linear; <1 lifts lows; >1 tames lows

    // Linear (0..1) → UI 0..1 via dB mapping + optional perceptual curve
    ~hud_map_linear_to_ui = ~hud_map_linear_to_ui ? { arg linearValue;
        var dbValue, normalizedValue, curvedValue, floorDb, topDb, gammaValue;
        floorDb    = ~hud_meter_floor_db ? -60.0;
        topDb      = ~hud_meter_top_db   ? -6.0;
        gammaValue = ~hud_meter_gamma    ? 1.0;

        dbValue = (max(linearValue, 1e-7)).log10 * 20.0;             // linear → dBFS
        normalizedValue = dbValue.linlin(floorDb, topDb, 0.0, 1.0);  // dBFS → 0..1
        normalizedValue = normalizedValue.clip(0.0, 1.0);
        curvedValue = normalizedValue.pow(gammaValue);
        curvedValue
    };

    // dB (e.g., -60..0) → UI 0..1 (sibling helper if a dB route is used anywhere)
    ~hud_map_db_to_ui = ~hud_map_db_to_ui ? { arg dbValue;
        var floorDb, topDb, gammaValue, normalizedValue;
        floorDb    = ~hud_meter_floor_db ? -60.0;
        topDb      = ~hud_meter_top_db   ? -6.0;
        gammaValue = ~hud_meter_gamma    ? 1.0;
        normalizedValue = dbValue.linlin(floorDb, topDb, 0.0, 1.0).clip(0.0, 1.0);
        normalizedValue.pow(gammaValue)
    };

    "[HUD] meter mapping helpers installed (floor/top/gamma)".postln;
    nil
};

// Schedule both on AppClock so they are present after HUD bring-up and after a reset
AppClock.sched(0.0, { ensureAmpRespondersInstalled.(); nil });
AppClock.sched(0.0, { installHudMeterMappingHelpers.(); nil });
)
