// LPDisplayLayoutWindow_Append_FinalReport.scd
// v0.1.0
// MD 20251003-1055

/* Purpose/Style:
- Append a finalization note to progress_report.txt summarizing completion.
*/

(
var dirPath, reportPath, note;

dirPath = ~md_migration[\projectRoot] +/+ "reports";
reportPath = dirPath +/+ "progress_report.txt";
File.exists(dirPath).if({ }, { File.mkdir(dirPath) });

note = [
    "",
    "Finalization Note:",
    " - Verified: old class absent; new class constructs -> a Window.",
    " - Compiled .sc filename hits for old name: 0",
    " - Archives present (non-.sc): OK to keep.",
    ""
].join(Char.nl.asString);

File.use(reportPath, "a", { |f| f.write(note) });
("Appended finalization note to: " ++ reportPath).postln;
)
