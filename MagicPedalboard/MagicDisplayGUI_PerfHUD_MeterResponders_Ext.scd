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
)
