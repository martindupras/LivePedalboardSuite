// Find_Rogue_Audio.scd
// v0.1.0
// MD 20251005-1202

/*
Purpose
- Print what's *actually* alive at the Proxy level and query the server tree.
- Helps spot unexpected sources that keep playing.
*/

(
var s = Server.default;

// 1) quick survey of NodeProxies
"— Ndef survey —".postln;
Ndef.all.keysValuesDo { |key, nd|
    ("  " ++ key.asString
      ++ "  isPlaying=" ++ nd.isPlaying
      ++ "  sourceClass=" ++ (nd.source ? "nil").class
    ).postln;
};

// 2) server tree snapshot
"— queryAllNodes — (watch console)".postln;
s.queryAllNodes;
)
