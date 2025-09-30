// INSTALL_AmpA_AmpB_Responders_Min.scd
// v0.1.0
// MD 2025-09-29

(
var ensureModelReady, installAmpResponders, updatesToLog, logKeyA, logKeyB;

updatesToLog = 6;
logKeyA = \ampA_to_model_log_once;
logKeyB = \ampB_to_model_log_once;

ensureModelReady = {
    ~md_levelsById   = ~md_levelsById   ? IdentityDictionary.new;
    ~md_lastMsgStamp = ~md_lastMsgStamp ? SystemClock.seconds.asFloat;
    nil
};

installAmpResponders = {
    var existingA, existingB;

    existingA = OSCdef.all.at(\ampA_to_model);
    if(existingA.notNil) { existingA.free };

    existingB = OSCdef.all.at(\ampB_to_model);
    if(existingB.notNil) { existingB.free };

    OSCdef(\ampA_to_model, { arg oscMessage;
        var leftLinear, rightLinear, logText;
        leftLinear  = (oscMessage.size >= 4).if({ oscMessage[3] }, { 0.0 }).asFloat.clip(0.0, 1.0);
        rightLinear = (oscMessage.size >= 5).if({ oscMessage[4] }, { 0.0 }).asFloat.clip(0.0, 1.0);
        ~md_levelsById.put(2001, [leftLinear, rightLinear]);
        ~md_lastMsgStamp = SystemClock.seconds.asFloat;

        if(updatesToLog > 0) {
            logText = "[ampA_to_model] A: L=" ++ leftLinear.round(0.01)
                ++ "  R=" ++ rightLinear.round(0.01);
            logText.postln;
            updatesToLog = updatesToLog - 1;
            if(updatesToLog <= 0) { "ampA/B model logging done.".postln };
        };
        nil
    }, "/ampA", recvPort: NetAddr.langPort);

    OSCdef(\ampB_to_model, { arg oscMessage;
        var leftLinear, rightLinear;
        leftLinear  = (oscMessage.size >= 4).if({ oscMessage[3] }, { 0.0 }).asFloat.clip(0.0, 1.0);
        rightLinear = (oscMessage.size >= 5).if({ oscMessage[4] }, { 0.0 }).asFloat.clip(0.0, 1.0);
        ~md_levelsById.put(2002, [leftLinear, rightLinear]);
        ~md_lastMsgStamp = SystemClock.seconds.asFloat;
        nil
    }, "/ampB", recvPort: NetAddr.langPort);

    "[HUD] ampA/ampB responders installed -> ~md_levelsById".postln;
};

ensureModelReady.();
installAmpResponders.();
)
