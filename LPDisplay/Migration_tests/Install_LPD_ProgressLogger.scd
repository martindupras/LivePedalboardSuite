// Install_LPD_ProgressLogger.scd
// v0.1.3
// MD 20251003-1518

/* Purpose / Style
- Append-only progress logger to OneDrive so notes survive recompile/restart.
- Uses File.exists / File.mkdir on STRING paths (portable).
- Style: tilde vars; var-first; lowercase; descriptive names; no server.sync.
*/

(
var baseDirPathString, logsDirPathString, logFilePathString, ensureDir, writeLine;

// 0) base dir in OneDrive
baseDirPathString = "~/Library/CloudStorage/OneDrive-TheOpenUniversity/LivePedalboardSuite".standardizePath;

//baseDirPathString = "~/LivePedalboardSuite".standardizePath;

// 1) Logs dir path (string)
logsDirPathString = baseDirPathString ++ "/Logs";

// 2) ensure Logs dir exists (portable: File.exists / File.mkdir)
ensureDir = { arg dirPathString;
    (File.exists(dirPathString)).if({
        // directory already exists
    },{
        File.mkdir(dirPathString);
        ("Created Logs directory: " ++ dirPathString).postln;
    });
    nil
};
ensureDir.(logsDirPathString);

// 3) setup logger function & path
logFilePathString = logsDirPathString ++ "/LPDisplay_Sessions.log";
~md_log_path = logFilePathString;

writeLine = { arg text;
    var fileHandle, lineString;
    lineString = Date.localtime.stamp ++ " | " ++ text.asString ++ Char.nl.asString;
    fileHandle = File(~md_log_path, "a");
    fileHandle.write(lineString);
    fileHandle.close;
    ("[logged] " ++ text).postln;
    nil
};

~md_log = { arg text; writeLine.(text) };

"LPD progress logger installed -> ".post; ~md_log_path.postln;
)