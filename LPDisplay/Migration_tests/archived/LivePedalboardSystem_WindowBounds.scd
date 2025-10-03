// LivePedalboardSystem_WindowBounds.scd
// v0.1.1
// MD 20251003-1136

/* Purpose/Style:
- Define *pure* helpers to save/load/apply window bounds safely.
- IMPORTANT: uses isNil.if to assign Function objects (no '??' auto-eval).
- Writes to <Extensions>/LivePedalboardSuite/prefs/<prefix>_window_bounds.txt
- Known-good SC only: File.exists, File.mkdir, File.use, split/asFloat.
*/

(
var ensureDefaults;

("Running: LivePedalboardSystem_WindowBounds.scd").postln;

ensureDefaults = {
    ~lps_prefsDir.isNil.if({
        ~lps_prefsDir = Platform.userExtensionDir +/+ "LivePedalboardSuite" +/+ "prefs";
    });

    ~lps_boundsFilePathForPrefix.isNil.if({
        ~lps_boundsFilePathForPrefix = { |prefix|
            var safePrefix;
            safePrefix = prefix ?? { ~lps_windowPrefix ?? { "MagicDisplayGUI" } };
            ~lps_prefsDir +/+ (safePrefix ++ "_window_bounds.txt")
        };
    });

    ~lps_saveWindowBounds.isNil.if({
        ~lps_saveWindowBounds = { |window, prefix|
            var filePath, rect, content;
            if(window.isNil) { "saveWindowBounds: window is nil".warn; ^nil };
            filePath = ~lps_boundsFilePathForPrefix.(prefix);
            File.exists(~lps_prefsDir).if({ }, { File.mkdir(~lps_prefsDir) });
            rect = window.bounds; // Rect(x, y, width, height)
            content = [rect.left, rect.top, rect.width, rect.height].collect(_.asString).join(" ");
            File.use(filePath, "w", { |f| f.write(content) });
            ("Saved bounds to: " ++ filePath ++ " -> " ++ content).postln;
            filePath
        };
    });

    ~lps_loadWindowBounds.isNil.if({
        ~lps_loadWindowBounds = { |prefix|
            var filePath, content, parts, rect;
            filePath = ~lps_boundsFilePathForPrefix.(prefix);
            File.exists(filePath).if({
                content = File.readAllString(filePath);
                parts = content.split($ );
                if(parts.size >= 4) {
                    rect = Rect(parts[0].asFloat, parts[1].asFloat, parts[2].asFloat, parts[3].asFloat);
                    ("Loaded bounds from: " ++ filePath ++ " -> " ++ rect.asString).postln;
                    rect
                } {
                    ("Bounds file malformed: " ++ filePath ++ " -> '" ++ content ++ "'").warn;
                    nil
                }
            }, {
                ("No saved bounds at: " ++ filePath).postln;
                nil
            })
        };
    });

    ~lps_applyLastWindowBounds.isNil.if({
        ~lps_applyLastWindowBounds = { |window, prefix|
            var rect;
            if(window.isNil) { "applyLastWindowBounds: window is nil".warn; ^nil };
            rect = ~lps_loadWindowBounds.(prefix);
            if(rect.notNil) {
                window.bounds = rect;
                ("Applied saved bounds: " ++ rect.asString).postln;
            };
            window
        };
    });

    ~lps_frontByPrefix.isNil.if({
        ~lps_frontByPrefix = { |prefix|
            var effectivePrefix, wins;
            effectivePrefix = prefix ?? { ~lps_windowPrefix ?? { "MagicDisplayGUI" } };
            wins = Window.allWindows.select({ |win| win.name.asString.beginsWith(effectivePrefix) });
            wins.notEmpty.if({ wins.first.front; wins.first }, { nil })
        };
    });
};

ensureDefaults.();
)
