// Finish_WriteStatus_SaveToOneDrive.scd
// v0.1.0
// MD timestamp: 2025-09-26 16:13 GMT+1

/*
Purpose
- Write an end-of-session status snapshot to OneDrive and return the file path.

What it records
- Timestamp, SC version, platform, sampleRate, server status, window count,
  suite path (under Extensions), and this file's location if available.

Style / Guard Rails
- Single () block; VAR-FIRST; finite; no non-local returns.
*/

(
var server, dirPath, pathName, stamp, filePath, writeLine, f, suitePath, windowCount, scVer, platformInfo;
var herePath;

server = Server.default;
suitePath = Platform.userExtensionDir +/+ "LivePedalboardSuite";
dirPath = Platform.userHomeDir +/+ "Library/CloudStorage/OneDrive-TheOpenUniversity/SC_MPB_Test";
pathName = PathName(dirPath);
stamp = Date.getDate.stamp.replace($:, $_);
filePath = dirPath +/+ ("status_" ++ stamp ++ ".txt");
scVer = Main.scVersionString;
platformInfo = Platform.name.asString ++ " " ++ Platform.architecture.asString;
windowCount = Window.allWindows.size;
herePath = thisProcess.nowExecutingPath ? "<interactive>";

pathName.isFolder.if({ }, { pathName.mkdirAll; });

writeLine = { arg txt; f.write(txt ++ Char.nl); };

f = File(filePath, "w");
writeLine.("=== MPB EOD STATUS SNAPSHOT ===");
writeLine.("timestamp: " ++ stamp);
writeLine.("sc_version: " ++ scVer);
writeLine.("platform: " ++ platformInfo);
writeLine.("server_running: " ++ server.serverRunning);
writeLine.("server_sampleRate: " ++ server.sampleRate);
writeLine.("windows_open: " ++ windowCount);
writeLine.("suite_path: " ++ suitePath);
writeLine.("script_path: " ++ herePath);
f.close;

("[EOD] wrote " ++ filePath).postln;
filePath
)
