// MD_Test_OneDrive_RoundTrip.scd
// v0.1.1
// MD 2025-09-26 18:58 BST

/* Purpose / Style
   Purpose: Detect a OneDrive root, create a test folder, write a file, read it back, and print results.
            Works with ~/Library/CloudStorage/OneDrive-* and legacy ~/OneDrive* names.
   Style:   Single () block; VAR-FIRST in every closure; descriptive lowercase names; no server.sync; finite print.
*/

(
var postBanner, expandPath, listFolders, findOneDriveRoot, writeThenRead;
var cloudRoot, homeRoot, foundRoot, testFolderPath, testFilePath, timeStampText, resultPath;

// Header
postBanner = {
    var headerText;
    headerText = "=== MD_TEST_ONEDRIVE_ROUND_TRIP ===";
    headerText.postln;
};

// Expand helper
expandPath = { arg pathString;
    var pn;
    pn = PathName(pathString.standardizePath);
    pn.fullPath
};

// Folder list helper
listFolders = { arg directoryPath;
    var pn, entries, indexCount, indexLimit, outList, item;
    pn = PathName(directoryPath);
    if(pn.isFolder.not) { [] } {
        entries = pn.entries;
        indexCount = 0; indexLimit = entries.size; outList = [];
        while({ indexCount < indexLimit }, {
            item = entries[indexCount];
            if(item.isFolder) { outList = outList.add(item.fullPath) };
            indexCount = indexCount + 1;
        });
        outList
    }
};

// Root finder
findOneDriveRoot = {
    var roots, candidates, indexCount, indexLimit, pathItem, baseOk;
    roots = [];

    cloudRoot = expandPath.("~/Library/CloudStorage");
    candidates = listFolders.(cloudRoot);
    indexCount = 0; indexLimit = candidates.size;
    while({ indexCount < indexLimit }, {
        pathItem = candidates[indexCount];
        baseOk = pathItem.asString.basename.beginsWith("OneDrive");
        if(baseOk) { roots = roots.add(pathItem) };
        indexCount = indexCount + 1;
    });

    homeRoot = expandPath.("~");
    candidates = listFolders.(homeRoot);
    indexCount = 0; indexLimit = candidates.size;
    while({ indexCount < indexLimit }, {
        pathItem = candidates[indexCount];
        baseOk = pathItem.asString.basename.beginsWith("OneDrive");
        if(baseOk) { roots = roots.add(pathItem) };
        indexCount = indexCount + 1;
    });

    if(roots.size > 0) { roots[0] } { nil }
};

// Writer/reader
writeThenRead = { arg folderPath;
    var okFolder, outFileName, outPath, readBackText;

    okFolder = PathName(folderPath).isFolder;
    if(okFolder.not) { File.mkdir(folderPath) };

    timeStampText = Date.getDate.stamp;
    outFileName = "sc_roundtrip_" ++ timeStampText ++ ".txt";
    outPath = folderPath ++ "/" ++ outFileName;

    File.use(outPath, "w", { arg fileRef; fileRef.write("Hello from SuperCollider at " ++ timeStampText) });
    readBackText = "";
    File.use(outPath, "r", { arg fileRef; readBackText = fileRef.readAllString });

    ("ODTEST: wrote " ++ outPath).postln;
    ("ODTEST: read  " ++ readBackText).postln;
    outPath
};

// —— run ————————————————————————————————————————————————————————————————
postBanner.();

foundRoot = findOneDriveRoot.();
if(foundRoot.isNil) {
    "⚠️ ODTEST: OneDrive root not found. Edit script to supply your OneDrive path explicitly.".warn;
    "   Example: set foundRoot = \"/Users/yourname/Library/CloudStorage/OneDrive-YourOrg\";".postln;
    resultPath = nil;
} {
    ("ODTEST: root = " ++ foundRoot).postln;
    testFolderPath = foundRoot ++ "/SC_MPB_Test";
    ("ODTEST: folder = " ++ testFolderPath).postln;
    resultPath = writeThenRead.(testFolderPath);
    "ODTEST: done.".postln;
};

// Final expression (so the block returns a value but uses no ^)
resultPath
)
