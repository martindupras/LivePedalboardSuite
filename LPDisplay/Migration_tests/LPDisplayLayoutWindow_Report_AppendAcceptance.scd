// LPDisplayLayoutWindow_Report_AppendAcceptance.scd
// v0.1.0
// MD 20251003-1110

/* Purpose:
- Append acceptance notes (basics, snapshot, resize) to progress_report.txt
*/

(
var reportDir, reportPath, note;

("Running: LPDisplayLayoutWindow_Report_AppendAcceptance.scd").postln;


reportDir = Platform.userExtensionDir +/+ "LivePedalboardSuite" +/+ "reports";
reportPath = reportDir +/+ "progress_report.txt";
File.exists(reportDir).if({ }, { File.mkdir(reportDir) });

note = [
    "",
    "Acceptance Notes (LPDisplayLayoutWindow):",
    " - Basics: constructed -> a Window",
    " - Snapshot: reports/LPDisplayLayoutWindow_layout_snapshot.txt",
    " - ResizeSanity: children inside content view (see console for WARN if any)",
    ""
].join(Char.nl.asString);

File.use(reportPath, "a", { |f| f.write(note) });
("Appended acceptance notes to: " ++ reportPath).postln;
)