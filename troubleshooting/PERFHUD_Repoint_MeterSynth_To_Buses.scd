// PERFHUD_Repoint_MeterSynth_To_Buses.scd
// v0.1.0
// MD 20250929-1518

(
var hasBusA, hasBusB, repointedText;

hasBusA = (~busA.notNil) && (~busA.respondsTo(\index));
hasBusB = (~busB.notNil) && (~busB.respondsTo(\index));

if(~md_levelsSynth.notNil) {
    if(hasBusA) { ~md_levelsSynth.set(\inBusA, ~busA.index) };
    if(hasBusB) { ~md_levelsSynth.set(\inBusB, ~busB.index) };
    repointedText = "99: md_levels4_from_busses repointed to inBusA=" ++
        (hasBusA.if({ ~busA.index }, { "unchanged" })) ++
        "  inBusB=" ++ (hasBusB.if({ ~busB.index }, { "unchanged" }));
    repointedText.postln;
}{
    "⚠️  md_levelsSynth not running; run 99_PerfHUD_MetersFromBusses.scd first.".warn;
}
)
