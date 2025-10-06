// Bridge_Meters_Universal.scd
// v0.1.0
// MD 2025-09-26 12:58 BST

/* Purpose / Style
   Make HUD meters move regardless of whether it listens to /md/levels or /ampA,/ampB.
   - Auto-discovers receiver ports for /ampA,/ampB responders and relays /md/levels to them.
   - Also updates the language-side model (~md_levelsById) from /ampA,/ampB (reverse path).
   - Idempotent: re-running replaces previous bridge.
   - var-first; descriptive lowercase; AppClock-only; no server.sync.
*/

(
var allDefs, ampPorts, collectAmpPorts, installMdToAmp, installAmpToModel, postSummary;

allDefs = OSCdef.all;

collectAmpPorts = {
    var ports;
    ports = IdentitySet.new;
    allDefs.keysValuesDo({ arg keySym, defObj;
        var pathValue, portValue;
        pathValue = defObj.tryPerform(\path);
        if(pathValue == "/ampA" or: { pathValue == "/ampB" }) {
            portValue = defObj.tryPerform(\recvPort) ? NetAddr.langPort;
            ports.add(portValue);
        };
    });
    // Always include langPort as a fallback
    ports.add(NetAddr.langPort);
    ports.asArray
};

installMdToAmp = { arg portArray;
    var existing;
    existing = OSCdef.all.at(\md_levels_bridge);
    if(existing.notNil) { existing.free };

    OSCdef(\md_levels_bridge, { arg msg, time, addr, recvPort;
        var replyId, leftVal, rightVal;
        var sendAddrs;

        if(msg.size < 5) { ^nil };
        replyId = msg[2];
        leftVal  = msg[3].asFloat.clip(0, 1);
        rightVal = msg[4].asFloat.clip(0, 1);

        // multicast to every port the HUD is listening on
        sendAddrs = portArray.collect({ arg portNum; NetAddr("127.0.0.1", portNum) });

        if(replyId == 2001) { sendAddrs.do({ arg na; na.sendMsg("/ampA", 0, -1, leftVal, rightVal) }) };
        if(replyId == 2002) { sendAddrs.do({ arg na; na.sendMsg("/ampB", 0, -1, leftVal, rightVal) }) };
        nil
    }, "/md/levels", recvPort: NetAddr.langPort);
};

installAmpToModel = {
    var ensureDict;
    ensureDict = { ~md_levelsById = ~md_levelsById ? IdentityDictionary.new };

    // /ampA -> model[2001]
    if(OSCdef.all.at(\ampA_to_model).notNil) { OSCdef.all.at(\ampA_to_model).free };
    OSCdef(\ampA_to_model, { arg msg;
        var leftVal, rightVal;
        ensureDict.();
        leftVal  = (msg.size >= 4).if({ msg[2] ? 0; msg[3] }, { 0 }).asFloat.clip(0, 1); // guard
        rightVal = (msg.size >= 5).if({ msg[4] }, { 0 }).asFloat.clip(0, 1);
        ~md_levelsById.put(2001, [leftVal, rightVal]);
        nil
    }, "/ampA", recvPort: NetAddr.langPort);

    // /ampB -> model[2002]
    if(OSCdef.all.at(\ampB_to_model).notNil) { OSCdef.all.at(\ampB_to_model).free };
    OSCdef(\ampB_to_model, { arg msg;
        var leftVal, rightVal;
        ensureDict.();
        leftVal  = (msg.size >= 4).if({ msg[2] ? 0; msg[3] }, { 0 }).asFloat.clip(0, 1);
        rightVal = (msg.size >= 5).if({ msg[4] }, { 0 }).asFloat.clip(0, 1);
        ~md_levelsById.put(2002, [leftVal, rightVal]);
        nil
    }, "/ampB", recvPort: NetAddr.langPort);
};

postSummary = { arg portsArray;
    var msg;
    msg = "Universal meter bridge active. ampA/ampB multicast ports: " ++ portsArray.asString;
    msg.postln;
};

// Main
ampPorts = collectAmpPorts.();
installMdToAmp.(ampPorts);
installAmpToModel.();
postSummary.(ampPorts);
)
