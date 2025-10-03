// LPDisplayLayoutWindow_Verify_Rename.scd
// v0.1.5
// MD 20251003-1055

/* Purpose/Style:
- Self-contained verification; safe to run anytime.
- Confirms:
  - content hits for old name = 0
  - .sc filename hits = 0 (must be 0)
  - new class loaded = true
  - old class missing = true
  - constructs -> a Window = true
*/

(
var ensureState, projectRoot, oldName, newName, searchExtensions;
var contentsHits, filenameHits, scFilenameHits, totalScanned;
var newClass, oldClass, createdWindow;
var okNewClassLoaded, okOldClassMissing, okConstructsWindow;

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
    ~md_log = ~md_log ?? { |message| ~md_migration[\logLines].add(message.asString); message.postln; };
    ~md_mark = ~md_mark ?? { |keySymbol, isDone=true| ~md_migration[\steps].put(keySymbol, isDone); };
};
ensureState.();

// config
projectRoot = ~md_migration[\projectRoot];
oldName = ~md_migration[\oldName];
newName = ~md_migration[\newName];
searchExtensions = [ "sc", "scd", "schelp", "md", "json", "yaml", "yml", "txt", "quark" ];

// scan contents
contentsHits = List.new;
totalScanned = 0;
PathName(projectRoot).deepFiles.do({ |pn|
    var filePath, ext, content;
    filePath = pn.fullPath;
    ext = pn.extension;
    ext = ext.isNil.if({ "" }, { ext.asString.toLower });
    if(searchExtensions.includes(ext)) {
        totalScanned = totalScanned + 1;
        content = File.readAllString(filePath);
        if(content.notNil and: { content.contains(oldName) }) {
            contentsHits.add(filePath);
        };
    };
});

// scan filenames
filenameHits = List.new;
scFilenameHits = List.new;
PathName(projectRoot).deepFiles.do({ |pn|
    var fileName;
    fileName = pn.fileName.asString;
    if(fileName.contains(oldName)) {
        filenameHits.add(pn.fullPath);
        if(fileName.endsWith(".sc")) { scFilenameHits.add(pn.fullPath) };
    };
});

// class presence and acceptance
newClass = newName.asSymbol.asClass;
oldClass = oldName.asSymbol.asClass;
okNewClassLoaded = newClass.notNil;
okOldClassMissing = oldClass.isNil;

createdWindow = okNewClassLoaded.if({
    newClass.respondsTo(\open).if({ newClass.open }, { newClass.new })
}, { nil });

okConstructsWindow = createdWindow.notNil and: { createdWindow.isKindOf(Window) };
okConstructsWindow.if({ createdWindow.front });

// summary
"— Verification Summary —".postln;
("Scanned files (contents): " ++ totalScanned.asString).postln;
("Content hits for old name: " ++ contentsHits.size.asString).postln;
("Filename hits for old name: " ++ filenameHits.size.asString).postln;
(" .sc filename hits (must be 0): " ++ scFilenameHits.size.asString).postln;
("New class loaded: " ++ okNewClassLoaded.asString).postln;
("Old class missing: " ++ okOldClassMissing.asString).postln;
("Constructs -> a Window: " ++ okConstructsWindow.asString).postln;

// update state
~md_migration[\hitFiles] = contentsHits;
~md_migration[\filenameHits] = filenameHits;
~md_migration[\lastOpenedWindow] = createdWindow;

~md_mark.(\scannedContents, true);
~md_mark.(\scannedFilenames, true);
(contentsHits.isEmpty).if({ ~md_mark.(\callSitesUpdated, true) });
(okOldClassMissing).if({ ~md_mark.(\oldFileRemoved, true) });
(okConstructsWindow).if({ ~md_mark.(\acceptancePassed, true) });

// return the window so you see '-> a Window'
createdWindow
)