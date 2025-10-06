// MD_Check_Suite_Symlink.scd
// v0.1.0
// MD 2025-09-26 19:55 BST

/* Purpose / Style
   Purpose: Report whether Extensions/LivePedalboardSuite is a symlink and, if so, where it points.
            This block is read-only (no filesystem changes).
   Style:   Single () block; VAR-FIRST in every closure; ≥3-char lowercase descriptive names;
            no single-letter locals; no server.sync; finite output; no non-local ^ in .scd.
*/

(
var postBanner, quotePath, extensionsDir, suiteExtPath, testCmd, isLinkExit, isSymlinkFlag;
var readCmd, pipeRef, linkTargetPath, expectedTargetPrefix, looksCorrectFlag;

postBanner = {
    var headerText;
    headerText = "=== MD_CHECK_SUITE_SYMLINK ===";
    headerText.postln;
};

quotePath = { arg rawPathString;
    var q;
    q = "\"" ++ rawPathString.asString ++ "\"";
    q
};

postBanner.();

// 1) Paths
extensionsDir = Platform.userExtensionDir.standardizePath;
suiteExtPath  = extensionsDir +/+ "LivePedalboardSuite";
("EXT: suite path = " ++ suiteExtPath).postln;

// 2) Is it a symlink? (exit=0 means yes)
testCmd = "[ -L " ++ quotePath.(suiteExtPath) ++ " ]";
isLinkExit = testCmd.unixCmd;
isSymlinkFlag = (isLinkExit == 0);
("EXT: is symlink? " ++ isSymlinkFlag.asString).postln;

// 3) If a symlink, read its target
linkTargetPath = "(not a symlink)";
if(isSymlinkFlag) {
    readCmd = "readlink " ++ quotePath.(suiteExtPath);
    pipeRef = Pipe.new(readCmd, "r");
    linkTargetPath = if(pipeRef.notNil) { pipeRef.getLine } { "(unavailable)" };
    if(pipeRef.notNil) { pipeRef.close };
};
("EXT: link target = " ++ linkTargetPath).postln;

// 4) Does the link target appear to live under OneDrive?
expectedTargetPrefix = "/Users/martindupras/Library/CloudStorage/OneDrive-TheOpenUniversity";
looksCorrectFlag = isSymlinkFlag and: { linkTargetPath.asString.beginsWith(expectedTargetPrefix) };
("OD : target under OneDrive? " ++ looksCorrectFlag.asString).postln;

// Final note
if(isSymlinkFlag.not) {
    "NOTE: Extensions/LivePedalboardSuite is a real folder, not a link. We can convert it to a symlink safely.".postln;
} {
    "NOTE: Good — Extensions/LivePedalboardSuite is a symlink.".postln;
};

nil
)
