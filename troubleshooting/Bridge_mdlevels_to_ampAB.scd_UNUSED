// Bridge_mdlevels_to_ampAB.scd
// v0.1.0
// MD 2025-09-26 12:43 BST

/* Purpose
   Bridge /md/levels to /ampA and /ampB so the HUD meters animate regardless of
   which responder is currently active in the window code.
   - replyID 2001 -> /ampA
   - replyID 2002 -> /ampB
*/

(
var senderAddr, installBridge;

senderAddr = NetAddr("127.0.0.1", NetAddr.langPort);

installBridge = {
    var existing;
    existing = OSCdef.all.at(\md_levels_bridge);
    if(existing.notNil) { existing.free };  // idempotent

    OSCdef(\md_levels_bridge, { arg msg, time, addr, recvPort;
        var replyId, leftVal, rightVal;
        if(msg.size < 5) { ^nil };  // guard

        replyId = msg[2];
        leftVal  = msg[3].asFloat.clip(0, 1);
        rightVal = msg[4].asFloat.clip(0, 1);

        // Relay to whichever responders the HUD already has
        if(replyId == 2001) { senderAddr.sendMsg("/ampA", 0, -1, leftVal, rightVal) };
        if(replyId == 2002) { senderAddr.sendMsg("/ampB", 0, -1, leftVal, rightVal) };
        nil
    }, "/md/levels", recvPort: NetAddr.langPort);
};

installBridge.();
"[/md/levels] -> [/ampA,/ampB] bridge installed.".postln;
)
