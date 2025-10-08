// Step4_ProbeSummary.scd
// v0.3.3
// MD 20251008-2115

(
("probeAcount=" ++ (~probeAcount ? 0)).postln;
("probeBcount=" ++ (~probeBcount ? 0)).postln;
("A ids: " ++ (~probeAid.asArray.sort.asString)).postln;  // expect [2001]
("B ids: " ++ (~probeBid.asArray.sort.asString)).postln;  // expect [2002]
)