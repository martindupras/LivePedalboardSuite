// Log_Session_Summary_Today.scd
// v0.1.2
// MD 20251003-1613

(
var systemPresent, cmBound, cmCandidate, line;

systemPresent = (~system.notNil);
cmCandidate = ~cm ? (
    ~system.tryPerform(\commandManager) ?
    ~system.tryPerform(\cmdManager) ?
    ~system.tryPerform(\cm) ?
    ~system.tryPerform(\manager)
);

cmBound = (
    cmCandidate.notNil and: { cmCandidate.display.notNil } and: { cmCandidate.display.respondsTo(\showExpectation) }
);

line = "LPD v0.1.6 OK; logger OK; auto-bind path pending; systemPresent="
    ++ systemPresent.asString
    ++ ", cmBound=" ++ cmBound.asString;

(~md_log.notNil).if({ ~md_log.(line) }, { line.postln });
)
