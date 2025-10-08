// ProbeSummary.scd
// v0.3.1
// MD 20251008-2056

(
var aIds, bIds;
aIds = (~probeAidList ? List.new).asArray.as(Set).asArray.sort;
bIds = (~probeBidList ? List.new).asArray.as(Set).asArray.sort;
("probeAcount=" ++ (~probeAcount ? 0)).postln;
("probeBcount=" ++ (~probeBcount ? 0)).postln;
("A ids seen: " ++ aIds.asString).postln;   // expect [2001]
("B ids seen: " ++ bIds.asString).postln;   // expect [2002]
nil
)