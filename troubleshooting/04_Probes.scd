// 04_Probes.scd
// v0.1.0
// MD 20250928-1948

(
// A — Dict snapshot used by the HUD (expect values < 1.0, changing)
var d = ~md_levelsById ? IdentityDictionary.new;
[1001, 2001, 2002].collect({ |k| [k, d[k]] }).postln;
)

(
// B — Log a few /md/levels_bus messages (expect id, then two floats < 1.0)
~probeCount = 0;
if(OSCdef.all.at(\probe_levels_bus).notNil) { OSCdef(\probe_levels_bus).free };
OSCdef(\probe_levels_bus, { |msg|
    var id=msg[2], l=msg[3].asFloat, r=msg[4].asFloat;
    ("[bus] id=" ++ id.asString ++ " l=" ++ l.round(0.003) ++ " r=" ++ r.round(0.003)).postln;
    ~probeCount = (~probeCount ? 0) + 1;
    if(~probeCount >= 12) { OSCdef(\probe_levels_bus).free; "~probe done".postln; };
    nil
}, "/md/levels_bus", recvPort: NetAddr.langPort);
"probe armed /md/levels_bus".postln;
)
