// Diag_Meters_QuickProbe_A_B_T.scd
// v0.1.0  MD 2025-09-26
(
var key, counts, lastA, lastB, lastT;
counts = IdentityDictionary[ 2001 -> 0, 2002 -> 0, 1001 -> 0 ];
lastA = [0.0, 0.0]; lastB = [0.0, 0.0]; lastT = [0.0, 0.0];

key = \md_levels_probe_once;
if(OSCdef.all.at(key).notNil) { OSCdef.all.at(key).free };
OSCdef(key, { arg msg;
    var id, l, r;
    if(msg.size < 5) { ^nil };
    id = msg[2]; l = msg[3].asFloat; r = msg[4].asFloat;
    if(id == 2001) { counts.put(2001, counts[2001] + 1); lastA = [l, r] };
    if(id == 2002) { counts.put(2002, counts[2002] + 1); lastB = [l, r] };
    if(id == 1001) { counts.put(1001, counts[1001] + 1); lastT = [l, r] };
    nil
}, "/md/levels", recvPort: NetAddr.langPort);

AppClock.sched(0.5, {
    var d = OSCdef.all.at(key);
    if(d.notNil) { d.free };
    ("RESULT A=" ++ counts[2001].asString ++ " " ++ lastA.asString
     ++ "  B=" ++ counts[2002].asString ++ " " ++ lastB.asString
     ++ "  T=" ++ counts[1001].asString ++ " " ++ lastT.asString).postln;
    nil
});
"[Probe] counting /md/levels for 0.5 s…".postln;
)
