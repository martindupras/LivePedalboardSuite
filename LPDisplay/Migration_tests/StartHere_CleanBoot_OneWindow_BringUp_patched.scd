// StartHere_CleanBoot_OneWindow_BringUp_patched.scd
// v0.2.2
// MD 20251003-1220

/* Purpose/Style:
- Single-file bring-up: installs helpers and brings up exactly ONE MagicDisplayGUI window.
- Applies saved bounds if present; stores ~lps_mainWindow.
- Known-good SC only; no onClose hooks; var-first; tilde vars; descriptive names.
- Returns '-> a Window'.
*/

(
var ensure, windowPrefix, desiredTitle, builderFunction, createdWindow;

// --- Install helpers (idempotent; no side effects except function defs) ---
("Running: LivePedalboardSystem_WindowManager_Install.scd").postln;

ensure = {
    ~lps_windowPrefix.isNil.if({ ~lps_windowPrefix = "MagicDisplayGUI" });

    ~lps_findWindowsByPrefix.isNil.if({
        ~lps_findWindowsByPrefix = { |prefix|
            var effectivePrefix, matchingWindows;
            effectivePrefix = prefix ?? { ~lps_windowPrefix };
            matchingWindows = Window.allWindows.select({ |win|
                var windowName;
                windowName = win.name.asString;
                windowName.notNil and: { windowName.beginsWith(effectivePrefix) }
            });
            matchingWindows
        };
    });

    ~lps_closeWindowsByPrefix.isNil.if({
        ~lps_closeWindowsByPrefix = { |prefix|
            var windowsToClose, closedCount;
            windowsToClose = ~lps_findWindowsByPrefix.(prefix).copy;
            closedCount = 0;
            windowsToClose.do({ |win|
                win.close;
                closedCount = closedCount + 1;
            });
            closedCount
        };
    });

    ~lps_bringUpSingleWindow.isNil.if({
        ~lps_bringUpSingleWindow = { |prefix, buildFunc, desiredTitleLocal|
            var effectivePrefix, existing, windowTitle, winLocal;
            effectivePrefix = prefix ?? { ~lps_windowPrefix };
            windowTitle = desiredTitleLocal ?? { effectivePrefix };
            existing = ~lps_findWindowsByPrefix.(effectivePrefix);
            if(existing.size == 1) {
                winLocal = existing.first;
                if(winLocal.name.asString != windowTitle) { winLocal.name = windowTitle };
                winLocal.front;
                winLocal
            } {
                ~lps_closeWindowsByPrefix.(effectivePrefix);
                winLocal = buildFunc.value(windowTitle);
                if(winLocal.notNil and: { winLocal.isKindOf(Window) }) {
                    winLocal.name = windowTitle;
                    winLocal.front;
                };
                winLocal
            }
        };
    });

    ~lps_frontByPrefix.isNil.if({
        ~lps_frontByPrefix = { |prefix|
            var effectivePrefix, wins;
            effectivePrefix = prefix ?? { ~lps_windowPrefix };
            wins = ~lps_findWindowsByPrefix.(effectivePrefix);
            wins.notEmpty.if({ wins.first.front; wins.first }, { nil })
        };
    });

    ~lps_frontOrBringUpByPrefix.isNil.if({
        ~lps_frontOrBringUpByPrefix = { |prefix, buildFunc, desiredTitleLocal|
            var effectivePrefix, win;
            effectivePrefix = prefix ?? { ~lps_windowPrefix };
            win = ~lps_frontByPrefix.(effectivePrefix);
            win.notNil.if({ win }, {
                ~lps_bringUpSingleWindow.(effectivePrefix, buildFunc, desiredTitleLocal)
            })
        };
    });

    ~lps_prefsDir.isNil.if({
        ~lps_prefsDir = Platform.userExtensionDir +/+ "LivePedalboardSuite" +/+ "prefs";
    });

    ~lps_boundsFilePathForPrefix.isNil.if({
        ~lps_boundsFilePathForPrefix = { |prefix|
            var safePrefix;
            safePrefix = prefix ?? { ~lps_windowPrefix };
            ~lps_prefsDir +/+ (safePrefix ++ "_window_bounds.txt")
        };
    });

    ~lps_saveWindowBounds.isNil.if({
        ~lps_saveWindowBounds = { |window, prefix|
            var filePath, rect, content;
            if(window.isNil) { "saveWindowBounds: window is nil".warn; ^nil };
            filePath = ~lps_boundsFilePathForPrefix.(prefix);
            File.exists(~lps_prefsDir).if({ }, { File.mkdir(~lps_prefsDir) });
            rect = window.bounds;
            if(rect.isNil) { "saveWindowBounds: window.bounds is nil".warn; ^nil };
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
};

ensure.();

// --- Bring up the single window ---
("Running: StartHere_BringUp_MagicDisplayGUI.scd").postln;

windowPrefix = "MagicDisplayGUI";
desiredTitle = "MagicDisplayGUI - LPDisplayLayout";

builderFunction = { |requestedTitle|
    var createdWindowLocal;
    createdWindowLocal = LPDisplayLayoutWindow.respondsTo(\open).if({
        LPDisplayLayoutWindow.open
    }, {
        LPDisplayLayoutWindow.new
    });
    createdWindowLocal.name = requestedTitle;
    createdWindowLocal
};

createdWindow = ~lps_bringUpSingleWindow.(windowPrefix, builderFunction, desiredTitle);
~lps_applyLastWindowBounds.(createdWindow, windowPrefix);
~lps_mainWindow = createdWindow;

// Return -> a Window
createdWindow
)