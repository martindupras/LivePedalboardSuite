// LPDisplayLayoutWindow_Verify_Rename.scd
// v0.1.5
// MD 20251003-1055

/* Purpose/Style:
- Self-contained verification of the rename (no external state required).
- Confirms:
  - content hits for old name = 0
  - filename hits for old name (info): lists any .sc hits (those would compile)
  - new class loaded = true
  - old class missing = true   <-- important
  - constructs -> a Window = true
- Style: var-first; descriptive names; no single-letter locals; no invented methods.
*/

(
var projectRoot, oldName, newName, searchExtensions;
var contentsHits, filenameHits, scFilenameHits, totalScanned;
var newClass, oldClass, createdWindow;
var okNewClassLoaded, okOldClassMissing, okConstructsWindow;

// Configuration
projectRoot = Platform.userExtensionDir +/+ "LivePedalboardSuite";
oldName = "LPDisplayLayoutTestWindow";
newName = "LPDisplayLayoutWindow";
searchExtensions = [ "sc", "scd", "schelp", "md", "json", "yaml", "yml", "txt", "quark" ];

// Scan contents for oldName
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

// Scan filenames for oldName + list only .sc hits (compiling files)
filenameHits = List.new;
scFilenameHits = List.new;
PathName(projectRoot).deepFiles.do({ |pn|
    var fileName, fullPath;
    fileName = pn.fileName.asString;
    fullPath = pn.fullPath;
    if(fileName.contains(oldName)) {
        filenameHits.add(fullPath);
        if(fileName.endsWith(".sc")) {
            scFilenameHits.add(fullPath);
        };
    };
});

// Class presence and acceptance
newClass = newName.asSymbol.asClass;
oldClass = oldName.asSymbol.asClass;
okNewClassLoaded = newClass.notNil;
okOldClassMissing = oldClass.isNil;

createdWindow = okNewClassLoaded.if({
    newClass.respondsTo(\open).if({ newClass.open }, { newClass.new })
}, { nil });

okConstructsWindow = createdWindow.notNil and: { createdWindow.isKindOf(Window) };
okConstructsWindow.if({ createdWindow.front });

// Summary
"— Verification Summary —".postln;
("Scanned files (contents): " ++ totalScanned.asString).postln;
("Content hits for old name: " ++ contentsHits.size.asString).postln;
("Filename hits for old name: " ++ filenameHits.size.asString).postln;
(" .sc filename hits (must be 0): " ++ scFilenameHits.size.asString).postln;
("New class loaded: " ++ okNewClassLoaded.asString).postln;
("Old class missing: " ++ okOldClassMissing.asString).postln;
("Constructs -> a Window: " ++ okConstructsWindow.asString).postln;

(scFilenameHits.notEmpty).if({
    "These .sc files still reference the old name and WILL be compiled:".postln;
    scFilenameHits.do({ |p| ("  - " ++ p).postln; });
});

// Return the window so you see '-> a Window' if successful.
createdWindow
)