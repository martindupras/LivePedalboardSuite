// Accept_Meters_QuickCheck_GUI.scd
// v0.1.0  MD 2025-09-26 16:10 BST

(
var key, counts, lastGA, lastGB, lastGT;
counts = IdentityDictionary[ 32001 -> 0, 32002 -> 0, 31001 -> 0 ];
lastGA = [0.0, 0.0]; lastGB = [0.0, 0.0]; lastGT = [0.0, 0.0];

key = \md_levels_gui_accept_once;
if(OSCdef.all.at(key).notNil) { OSCdef.all.at(key).free };

OSCdef(key, { arg msg;
    var id, l, r;
    if(msg.size < 5) { ^nil };
    id = msg[2]; l = msg[3].asFloat; r = msg[4].asFloat;
    if(id == 32001) { counts.put(32001, counts[32001] + 1); lastGA = [l, r] };
    if(id == 32002) { counts.put(32002, counts[32002] + 1); lastGB = [l, r] };
    if(id == 31001) { counts.put(31001, counts[31001] + 1); lastGT = [l, r] };
    nil
}, "/md/levels_gui", recvPort: NetAddr.langPort);

AppClock.sched(0.5, {
    var d = OSCdef.all.at(key), line;
    if(d.notNil) { d.free };
    line = "[ACCEPT_GUI] GA=" ++ counts[32001].asString ++ " " ++ lastGA.asString
        ++ "  GB=" ++ counts[32002].asString ++ " " ++ lastGB.asString
        ++ "  GT=" ++ counts[31001].asString ++ " " ++ lastGT.asString;
    line.postln;
    nil
});

"[ACCEPT_GUI] counting /md/levels_gui for 0.5 s…".postln;
)
