// LPDisplayLayoutWindow_Check_MigrationNames.sc
// v0.1.0
// MD 2025-10-03 10:10 GMT+01

/* Purpose:
- Ensure ~md_migration has correct old/new names for verification.
*/

(
var currentOld, currentNew, expectedOld, expectedNew, needsFix;

expectedOld = "LPDisplayLayoutTestWindow";
expectedNew = "LPDisplayLayoutWindow";

currentOld = ~md_migration[\oldName];
currentNew = ~md_migration[\newName];

("oldName (in state): " ++ currentOld).postln;
("newName (in state): " ++ currentNew).postln;

needsFix = (currentOld != expectedOld) or: { currentNew != expectedNew };

needsFix.if({
    ~md_migration[\oldName] = expectedOld;
    ~md_migration[\newName] = expectedNew;
    ~md_log.("Corrected migration names in state to expected values.");
}, {
    ~md_log.("Migration names already correct.");
});
)