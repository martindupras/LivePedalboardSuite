// LPDisplayLayoutWindow_Migration_Status.scd
// v0.1.0
// MD 20251003-1055

/* Purpose/Style:
- Print and return an Event snapshot of current migration flags.
*/

(
var snapshot;
snapshot = (
    scannedContents: ~md_migration[\steps][\scannedContents],
    scannedFilenames: ~md_migration[\steps][\scannedFilenames],
    callSitesUpdated: ~md_migration[\steps][\callSitesUpdated],
    shimInPlace: ~md_migration[\steps][\shimInPlace],
    oldFileRemoved: ~md_migration[\steps][\oldFileRemoved],
    helpUpdated: ~md_migration[\steps][\helpUpdated],
    acceptancePassed: ~md_migration[\steps][\acceptancePassed],
    reportWritten: ~md_migration[\steps][\reportWritten]
);
"— Migration Status Snapshot —".postln;
snapshot.postln;
snapshot
)