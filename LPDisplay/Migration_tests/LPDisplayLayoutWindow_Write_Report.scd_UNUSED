// LPDisplayLayoutWindow_Write_Report.scd
// v0.1.4
// MD 20251003-1042

/* Purpose/Style:
- Write progress_report.txt under <Extensions>/LivePedalboardSuite/reports
- Self-contained: initializes default state if ~md_migration is missing.
- Uses File.mkdir + File.use (known-good).
*/

(
var ensureState, dirPath, reportPath, lines, stepsDict, keys, content;

// Ensure defaults if state missing
ensureState = {
    var stepsEvent;
    ~md_migration = ~md_migration ?? {
        stepsEvent = (
            scannedContents: false, scannedFilenames: false, callSitesUpdated: false,
            shimInPlace: false, oldFileRemoved: false, helpUpdated: false,
            acceptancePassed: false, reportWritten: false
        );
        (
            projectRoot: Platform.userExtensionDir +/+ "LivePedalboardSuite",
            oldName: "LPDisplayLayoutTestWindow",
            newName: "LPDisplayLayoutWindow",
            steps: stepsEvent,
            logLines: List.new, hitFiles: List.new, filenameHits: List.new,
            updatedFiles: List.new, helpFiles: List.new
        )
    };
};
ensureState.();

// Paths
dirPath = ~md_migration[\projectRoot] +/+ "reports";
reportPath = dirPath +/+ "progress_report.txt";

// Ensure directory exists
File.exists(dirPath).if({ }, { File.mkdir(dirPath) });

// Build content
stepsDict = ~md_migration[\steps];
keys = stepsDict.keys.asArray.sort;

lines = List.new;
lines.add("Rename Migration Report: LPDisplayLayoutTestWindow -> LPDisplayLayoutWindow");
lines.add("");
lines.add("Root: " ++ ~md_migration[\projectRoot]);
lines.add("");

lines.add("Steps:");
keys.do({ |k| lines.add(" - " ++ k.asString ++ ": " ++ stepsDict[k].asString) });
lines.add("");

lines.add("Content hits (last scan): " ++ ~md_migration[\hitFiles].size);
~md_migration[\hitFiles].do({ |p| lines.add("   - " ++ p) });
lines.add("");

lines.add("Filename hits (last scan): " ++ ~md_migration[\filenameHits].size);
~md_migration[\filenameHits].do({ |p| lines.add("   - " ++ p) });
lines.add("");

lines.add("Updated files (manual, recorded): " ++ ~md_migration[\updatedFiles].size);
~md_migration[\updatedFiles].do({ |p| lines.add("   - " ++ p) });
lines.add("");

lines.add("Help files touched (recorded): " ++ ~md_migration[\helpFiles].size);
~md_migration[\helpFiles].do({ |p| lines.add("   - " ++ p) });
lines.add("");

lines.add("Log:");
~md_migration[\logLines].do({ |msg| lines.add(" - " ++ msg) });

content = lines.join(Char.nl.asString);

// Write file
File.use(reportPath, "w", { |f| f.write(content) });
("Wrote: " ++ reportPath).postln;

~md_mark.(\reportWritten, true);
~md_printStatus.();
)