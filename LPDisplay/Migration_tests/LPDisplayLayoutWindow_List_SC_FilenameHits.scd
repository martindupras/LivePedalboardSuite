// LPDisplayLayoutWindow_List_SC_FilenameHits.scd
// v0.1.1
// MD 20251003-1055

/* Purpose/Style:
- Quick helper to list ONLY .sc filename hits for the old name (compiled files).
*/

(
var projectRoot, oldName, scHits;

projectRoot = Platform.userExtensionDir +/+ "LivePedalboardSuite";
oldName = "LPDisplayLayoutTestWindow";

scHits = List.new;
PathName(projectRoot).deepFiles.do({ |pn|
    var fileName, fullPath;
    fileName = pn.fileName.asString;
    fullPath = pn.fullPath;
    if(fileName.contains(oldName) and: { fileName.endsWith(".sc") }) {
        scHits.add(fullPath);
    };
});

"— .sc filename hits for old name —".postln;
scHits.do({ |p| ("  - " ++ p).postln; });
(scHits.isEmpty).if({ "None.".postln; });
)