// Make_Project_Inventory.scd
// v0.1.13
// MD 20251005-1949

/*
Purpose
- Build a concise, readable manifest of the LivePedalboardSuite:
  • Top-level tree (depth 2) for quick orientation
  • List all .sc / .scd files with their first 3 header lines (filename / version / MD stamp)
  • Confirm the adapter file path: adapter_CommandTree_to_MagicPedalboard.scd (if present)
- Opens a new IDE Document with the inventory text (no file I/O).
  The FIRST LINE is the intended filename so you can copy-paste it when saving.

Style
- var-first; lowercase; descriptive variable names; no single-letter locals; no server.sync; conservative file reads; no non-local returns.
*/

(
var candidateRoots, chosenRootDirectoryPath, rootDirectoryPath;
var linesList, newlineChar, stampYYMMDD_HHMM, mdStampYYYYMMDD_HHMM, separatorLine;
var addString, addSeparator, addKeyValueLine, addSectionTitle;
var isSuperColliderCodeFile, relativePathOf, printTreeDepth2, collectFirstHeaderLines;
var inventoryBodyText, intendedFileName, documentTitle, inventoryDocument;

// ----- timestamps
newlineChar = Char.nl;
stampYYMMDD_HHMM = Date.getDate.stamp;  // e.g., "251005_1949"
mdStampYYYYMMDD_HHMM = (
    "20" ++ stampYYMMDD_HHMM.copyRange(0, 1)   // YY → YYYY with "20" prefix
    ++ stampYYMMDD_HHMM.copyRange(2, 3)        // MM
    ++ stampYYMMDD_HHMM.copyRange(4, 5)        // DD
    ++ "-" ++ stampYYMMDD_HHMM.copyRange(7, 10)  // HHMM
);

// intended filename (copy-paste this when saving)
intendedFileName = "Project_Inventory_" ++ stampYYMMDD_HHMM ++ ".txt";

// ----- helpers to build the text
separatorLine = "--------------------------------------------------------------------------------";
linesList = List.new;

addString = { |stringToAdd| linesList.add(stringToAdd) };
addSeparator = { linesList.add(separatorLine) };
addKeyValueLine = { |labelKey, labelValue| linesList.add(labelKey ++ ": " ++ labelValue.asString) };
addSectionTitle = { |sectionTitle|
    linesList.add("");
    linesList.add("===== " ++ sectionTitle ++ " =====");
};

isSuperColliderCodeFile = { |pathName|
    var fileExtension;
    fileExtension = pathName.extension ? "";
    ["sc", "scd"].includes(fileExtension.asString.toLower)
};

// ----- locate suite root (prefer OneDrive copy that contains MagicPedalboard/)
candidateRoots = [
    (Platform.userHomeDir ++ "/Library/CloudStorage/OneDrive-TheOpenUniversity/LivePedalboardSuite").standardizePath,
    (Platform.userExtensionDir ++ "/LivePedalboardSuite").standardizePath,
    (Platform.userHomeDir ++ "/PhD_projects/LivePedalboardSuite").standardizePath
];

chosenRootDirectoryPath = nil;
candidateRoots.do { |candidatePath|
    if(File.exists(candidatePath) and: { File.exists(candidatePath ++ "/MagicPedalboard") }) {
        chosenRootDirectoryPath = candidatePath;
    };
};
if(chosenRootDirectoryPath.isNil) {
    candidateRoots.do { |candidatePath|
        if(File.exists(candidatePath)) { chosenRootDirectoryPath = candidatePath };
    };
};
if(chosenRootDirectoryPath.isNil) {
    chosenRootDirectoryPath = (Platform.userExtensionDir ++ "/LivePedalboardSuite").standardizePath;
    File.mkdir(chosenRootDirectoryPath);  // last resort so the script can still run
};

rootDirectoryPath = chosenRootDirectoryPath;

// relative-path helper
relativePathOf = { |fullPathString|
    fullPathString.asString.replace(rootDirectoryPath, "").replace("//", "/")
};

// ----- directory tree (depth 2)
printTreeDepth2 = { |directoryPath|
    var directoryPathName, levelOneDirectories;

    if(File.exists(directoryPath).not) {
        addString.("[!] Directory does not exist: " ++ directoryPath);
    }{
        directoryPathName = PathName.new(directoryPath);

        addString.("ROOT: " ++ directoryPath);
        addSeparator.();

        // level 0 files
        directoryPathName.files.do { |filePathName|
            addString.("- " ++ relativePathOf.(filePathName.fullPath));
        };

        // level 1 folders and their files (depth 2 total)
        levelOneDirectories = directoryPathName.folders;
        levelOneDirectories.do { |levelOnePathName|
            addString.("> " ++ relativePathOf.(levelOnePathName.fullPath));

            // files in level-one folder
            PathName.new(levelOnePathName.fullPath).files.do { |levelOneFilePathName|
                addString.("  - " ++ relativePathOf.(levelOneFilePathName.fullPath));
            };

            // subfolders one level deeper
            PathName.new(levelOnePathName.fullPath).folders.do { |levelTwoPathName|
                addString.("  > " ++ relativePathOf.(levelTwoPathName.fullPath));
                PathName.new(levelTwoPathName.fullPath).files.do { |levelTwoFilePathName|
                    addString.("    - " ++ relativePathOf.(levelTwoFilePathName.fullPath));
                };
            };
        };
    };
};

// ----- collect first 3 header lines from .sc/.scd
collectFirstHeaderLines = {
    var recursePathname, rootPathName;

    addSectionTitle.("Code files with headers (.sc / .scd)");
    addString.("(first 3 lines per file, if present: filename / version / MD stamp)");
    addSeparator.();

    recursePathname = { |currentPathName|
        currentPathName.files.do { |filePathName|
            var fileFullPath, fileContents, headerLines, headerLine1, headerLine2, headerLine3;

            if(isSuperColliderCodeFile.(filePathName)) {
                fileFullPath = filePathName.fullPath;

                fileContents = "";
                File.use(fileFullPath, "r", { |fileHandle| fileContents = fileHandle.readAllString; });

                headerLines = fileContents.split(Char.nl);
                headerLine1 = (headerLines.size > 0).if({ headerLines[0] }, { "" });
                headerLine2 = (headerLines.size > 1).if({ headerLines[1] }, { "" });
                headerLine3 = (headerLines.size > 2).if({ headerLines[2] }, { "" });

                addString.(relativePathOf.(fileFullPath));
                addString.(" " ++ headerLine1);
                addString.(" " ++ headerLine2);
                addString.(" " ++ headerLine3);
                addString.("");
            };
        };

        currentPathName.folders.do { |childFolderPathName|
            recursePathname.(PathName.new(childFolderPathName.fullPath));
        };
    };

    rootPathName = PathName.new(rootDirectoryPath);
    recursePathname.(rootPathName);
};

// -------------------- build the inventory text (no file writes)
// 1) Put the intended filename on line 1 for copy-paste when saving
// 2) Then the rest of the inventory body
linesList = List.new; // reset to assemble the body cleanly
addString.("Make_Project_Inventory.scd - Project Inventory");
addKeyValueLine.("Generated", mdStampYYYYMMDD_HHMM);
addKeyValueLine.("UserExtensionDir", Platform.userExtensionDir);
addKeyValueLine.("Chosen suite root", rootDirectoryPath);
addSeparator.();

addSectionTitle.("Directory tree (depth 2)");
printTreeDepth2.(rootDirectoryPath);

addSectionTitle.("Adapter file");
{
    var adapterFileCandidatePath;
    adapterFileCandidatePath = (rootDirectoryPath ++ "/MagicPedalboard/adapter_CommandTree_to_MagicPedalboard.scd").standardizePath;
    addKeyValueLine.(
        "adapter_CommandTree_to_MagicPedalboard.scd",
        File.exists(adapterFileCandidatePath).if({ adapterFileCandidatePath }, { "[missing]" })
    );
};

collectFirstHeaderLines.();

inventoryBodyText = linesList.collect({ |element| element.asString }).join(newlineChar);

// Prepend the intended filename as the very first line
inventoryBodyText = intendedFileName ++ newlineChar ++ inventoryBodyText;

// -------------------- open a new IDE document; you save it manually
documentTitle = intendedFileName; // pre-fills the save name on many setups
inventoryDocument = Document.new(documentTitle, inventoryBodyText);
inventoryDocument.front;
("Inventory prepared. First line is the filename to copy-paste: " ++ intendedFileName).postln;
// End
)