// MD_EOD_Status_Snapshot_FIXED.scd
// v0.1.1
// MD 2025-09-26 16:56 BST

/* Purpose / Style
   Purpose: Record where SC is loading LivePedalboardSuite from and write a status file to OneDrive.
   Style:   Single () block; var-first in all closures; ≥3-char lowercase descriptive names;
            no single-letter locals; no non-local ^; finite output.
*/

(
var postBanner, writeStatus, isSymlink, readLinkTarget;
var extensionsDir, extSuitePath, odRootPath, statusFolderPath, outFilePath, linkTargetText, isLink, exitCode;

// ---- header ----
postBanner = {
    var headerText;
    headerText = "=== MD_EOD_STATUS_SNAPSHOT (FIXED) ===";
    headerText.postln;
};

// ---- helpers (var-first inside closures) ----
isSymlink = { arg pathString;
    var testCmd, code, flag;
    testCmd = "[ -L \"" ++ pathString ++ "\" ]";
    code = testCmd.unixCmd;        // 0 if symlink, non-zero otherwise
    flag = (code == 0);
    flag
};

readLinkTarget = { arg pathString;
    var pipeRef, cmd, line;
    cmd = "readlink \"" ++ pathString ++ "\"";
    pipeRef = Pipe.new(cmd, "r");
    if(pipeRef.isNil) { "(unavailable)" } {
        line = pipeRef.getLine ? "(unavailable)";
        pipeRef.close;
        line
    }
};

writeStatus = { arg folderPath, bodyText;
    var ensureFolderOk, fileName, fullPath;
    ensureFolderOk = PathName(folderPath).isFolder;
    if(ensureFolderOk.not) { File.mkdir(folderPath) };
    fileName = "sc_status_" ++ Date.getDate.stamp ++ ".txt";
    fullPath = folderPath +/+ fileName;
    File.use(fullPath, "w", { arg fileRef; fileRef.write(bodyText) });
    ("EOD: wrote " ++ fullPath).postln;
    fullPath
};

// ---- run ----
postBanner.();

extensionsDir  = Platform.userExtensionDir.standardizePath;
extSuitePath   = extensionsDir +/+ "LivePedalboardSuite";
("EXT: " ++ extSuitePath).postln;

isLink = isSymlink.(extSuitePath);
if(isLink) {
    linkTargetText = readLinkTarget.(extSuitePath);
} {
    linkTargetText = "(not a symlink)";
};
("EXT: target = " ++ linkTargetText).postln;

// OneDrive folder we’re using today
odRootPath = "/Users/martindupras/Library/CloudStorage/OneDrive-TheOpenUniversity";
statusFolderPath = odRootPath +/+ "SC_MPB_Test";

outFilePath = writeStatus.(statusFolderPath,
    "EOD snapshot at " ++ Date.getDate.stamp
    ++ "\nExtensions dir         = " ++ extensionsDir
    ++ "\nSuite path             = " ++ extSuitePath
    ++ "\nSuite link target      = " ++ linkTargetText
    ++ "\n"
);

// final expression (implicit return; no ^ in .scd)
outFilePath
)
