// PERFHUD_Bus_Indices_Inspect.scd
// v0.1.0
// MD 20250929-1518

(
var hasBusA, hasBusB, summaryText;

hasBusA = (~busA.notNil) && (~busA.respondsTo(\index));
hasBusB = (~busB.notNil) && (~busB.respondsTo(\index));

summaryText =
    "[bus indices] A=" ++ (hasBusA.if({ ~busA.index }, { "nil" })) ++
    "  B=" ++ (hasBusB.if({ ~busB.index }, { "nil" }));

summaryText.postln;
)
