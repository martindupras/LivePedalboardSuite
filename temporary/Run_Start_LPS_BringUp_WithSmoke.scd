// Run_Start_LPS_BringUp_WithSmoke.scd
// v0.9.2
// MD 20251006-1224

/*
Purpose
- Execute the current Start_LivePedalboardSuite_BringUp.scd (LPDisplay path),
  verify the LPDisplay window appears, and play a short beep for visual sanity.
- Returns -> a Window (the LPDisplay window) when successful.

Style
- STRICT: var-first, descriptive lowercase names, no single-letter locals, no non-local returns (^).
- Known-good sclang only. No server.sync; only s.waitForBoot, s.initTree, s.defaultGroup.freeAll.
- AppClock only for GUI timing.

Notes
- This runner does NOT modify your Start script; it simply reads & interprets it.
- Beep is generated audio (no SoundIn), then freed automatically.
*/

(
var nowStamp, userExtDir, suiteRoot;
var starterRelPath, starterFullPath;
var readText, interpretFile, findLPDisplayWindow, openInfoDoc;
var s, win, doc, beepSynth, ticker;

// ----- config -----
nowStamp      = Date.getDate.stamp;
userExtDir    = Platform.userExtensionDir;
suiteRoot     = (userExtDir ++ "/LivePedalboardSuite").standardizePath;
starterRelPath = "temporary/Start_LivePedalboardSuite_BringUp.scd";
starterFullPath = (suiteRoot ++ "/" ++ starterRelPath).standardizePath;

// ----- helpers -----
readText = { arg fullPath;
    var text;
    text = "";
    File.use(fullPath, "r", { arg f; text = f.readAllString; });
    text ? ""
};

interpretFile = { arg fullPath;
    var src;
    src = readText.value(fullPath);
    if(src.size > 0) { src.interpret } { "/* empty file */".interpret };
    nil
};

// Heuristic: look for an LPDisplay window by name
findLPDisplayWindow = {
    var wins, hit, nameStr;
    wins = Window.allWindows ? [];
    hit = nil;
    wins.do({ arg w;
        nameStr = w.name ? "";
        if(
            nameStr.contains("LPDisplay") or: {
                nameStr.contains("Layout") or: { nameStr.contains("MagicDisplayGUI") }
            }
        ) {
            hit = w;
        };
    });
    hit
};

openInfoDoc = { arg linesArray;
    var d;
    d = Document.new("BringUp report (" ++ nowStamp ++ ")", linesArray.join(Char.nl.asString));
    d.front;
    d
};

// ----- begin -----
s = Server.default;

// clean server boot (no server.sync)
if(s.serverRunning.not) {
    s.waitForBoot({
        ("Server booted @ " ++ nowStamp).postln;
    });
} {
    "Server already running; proceeding with init.".postln;
};

// ensure known state
s.initTree;
s.defaultGroup.freeAll;

// run the Start script (must use LPDisplay path)
if(File.exists(starterFullPath)) {
    ("Running: " ++ starterRelPath).postln;
    interpretFile.value(starterFullPath);
} {
    doc = openInfoDoc.value([
        "ERROR: Starter not found",
        "Expected at: " ++ starterFullPath,
        "",
        "Check Platform.userExtensionDir and that your suite root contains:",
        "  /LivePedalboardSuite/" ++ starterRelPath
    ]);
    doc // return -> a Document; early exit
};

// small delay for windows to appear (GUI only)
AppClock.sched(0.1, {
    win = findLPDisplayWindow.value;
    if(win.isNil) {
        doc = openInfoDoc.value([
            "LPDisplay window not detected.",
            "Looked for window names containing: LPDisplay / Layout / MagicDisplayGUI",
            "",
            "Tip: Verify your Start script creates LPDisplayLayoutWindow and brings it front."
        ]);
        doc.front;
        // still finish with doc to avoid nil return
    } {
        // short sanity beep so meters can show life
        beepSynth = {
            var env, sig;
            env = Env.perc(0.005, 0.25, curve: -4).kr(doneAction: 2);
            sig = SinOsc.ar(880) * 0.1 * env;
            (sig ! 2)
        }.play;

        // bring the display to front; return it
        win.front;

        // post a small banner to console
        "LPDisplay bring-up OK — short beep played; window front.".postln;
    };
    // return the window (or doc fallback) as last value in AppClock
    win ? doc
});
)
