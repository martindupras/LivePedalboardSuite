// MD_BringUp_GridDemo_FeedA_SaveMeters_OneDrive.scd
// v0.1.0
// MD 2025-09-26 19:12 BST

/* Purpose / Style
   Purpose:
     • Loud console headers; clean-boot bring-up.
     • Single MagicDisplayGUI GridDemo window; bind CommandManager.display if present.
     • Generated-audio test source Ndef(\testmelody) at modest level.
     • Feed chain A from testmelody using Ndef(left) <<> Ndef(right).
     • Raw amplitude taps on A/B → /md/levels (A=2001, B=2002).
     • Finite sniffer: print 6 lines (1 Hz) AND append to OneDrive log; auto-free listener.
     • Tiny overlay meters on the existing GUI (top-left) for ~4.5 s; auto-stop.
     • Final expression returns → a Window.
   Style:
     • Single () block; VAR-FIRST in EVERY block/closure; ≥3-char lowercase descriptive names;
       no single-letter locals; no server.sync; AppClock for GUI; known-good SC syntax only.
*/

(
var postBanner, findWindowByPrefix, ensureGridDemoWindow, freeOscIfPresent, stopRoutineIfPresent;
var serverRef, guiWindow, systemRef, commandManagerRef;
var oneDriveRoot, sessionFolderPath, logFilePath, timeStampText;
var oscKeyLevels, linesRemaining, overlayView, overlayTicksRemaining, overlayRoutine;
var valuesById;

// ——— loud header ——————————————————————————————————————————————————————————————
postBanner = {
    var headerText;
    headerText = "=== MD_BRINGUP_GRIDDEMO_FEEDA_SAVEMETERS_ONEDRIVE ===";
    headerText.postln;
};

// ——— helpers (VAR-FIRST in closures) ————————————————————————————————————————
findWindowByPrefix = { arg prefixString;
    var windowsList, indexCount, indexLimit, windowRef, nameString, foundWindow;
    windowsList = Window.allWindows;
    indexCount = 0; indexLimit = windowsList.size; foundWindow = nil;
    while({ indexCount < indexLimit }, {
        windowRef = windowsList[indexCount];
        nameString = windowRef.tryPerform(\name);
        if(nameString.notNil and: { nameString.asString.beginsWith(prefixString) }) {
            foundWindow = windowRef;
            indexCount = indexLimit; // break
        } {
            indexCount = indexCount + 1;
        };
    });
    foundWindow
};

ensureGridDemoWindow = {
    var priorWin, guiObj, newWin;
    "STEP GUI: ensuring a single MagicDisplayGUI window (GridDemo)…".postln;
    priorWin = findWindowByPrefix.("MagicDisplayGUI");
    if(priorWin.notNil) {
        priorWin.close;
        "GUI: closed existing MagicDisplayGUI".postln;
    };
    guiObj = MagicDisplayGUI_GridDemo.new;
    systemRef = ~system;
    if(systemRef.notNil) {
        commandManagerRef = systemRef.commandManager;
        if(commandManagerRef.notNil and: { commandManagerRef.display.isNil }) {
            commandManagerRef.display = guiObj;
            "GUI: bound CommandManager.display to GridDemo".postln;
        };
    };
    newWin = findWindowByPrefix.("Magic