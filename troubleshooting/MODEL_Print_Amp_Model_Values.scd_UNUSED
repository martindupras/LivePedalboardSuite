// MODEL_Print_Amp_Model_Values.scd
// v0.1.1
// MD 2025-09-29

(
var linesRemaining, printOnce;

linesRemaining = 6;

printOnce = {
    var levelsA, levelsB, reportText;
    levelsA = ~md_levelsById.atFail(2001, { [0.0, 0.0] });
    levelsB = ~md_levelsById.atFail(2002, { [0.0, 0.0] });
    reportText = "model A=" ++ levelsA ++ "   B=" ++ levelsB;
    reportText.postln;

    linesRemaining = linesRemaining - 1;
    if(linesRemaining > 0) {
        AppClock.sched(0.5, { printOnce.(); nil });
    }{
        nil
    };
};

AppClock.sched(0.0, { printOnce.(); nil });
)
