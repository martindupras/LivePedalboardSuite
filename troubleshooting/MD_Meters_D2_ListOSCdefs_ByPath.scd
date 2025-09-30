// MD_Meters_D2_ListOSCdefs_ByPath.scd
// v0.1.0
// MD timestamp: 2025-09-28 10:05 GMT+1

/*
Purpose
- Print all OSCdef listeners whose path mentions md/levels/meter.
- Confirms whether the PerfHUD window registered a listener and how it matches.
*/

(
var items, printOne;

items = List.new;

printOne = { arg keySym, def;
    var p, t, ps;
    p  = def.path;
    t  = def.argTemplate;
    ps = p ? "";
    ((ps.contains("md") or: { ps.contains("levels") or: { ps.contains("meter") } })).if({
        ("OSCdef " ++ keySym.asString
            ++ " : path=" ++ ps
            ++ "  template=" ++ (t ? nil).asString).postln;
        items.add(keySym);
    });
};

OSCdef.all.keysValuesDo { arg k, d; printOne.(k, d) };

("Found " ++ items.size ++ " OSCdef(s) matching 'md|levels|meter'").postln;
)
