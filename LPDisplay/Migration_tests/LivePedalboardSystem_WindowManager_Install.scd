// LivePedalboardSystem_WindowManager_Install.scd
// v0.2.2
// MD 20251003-1248

/* Purpose/Style:
- Install ALL LivePedalboardSystem GUI helpers right here (single source of truth):
  * policy prefix
  * find/close/bring-up (single-window invariant)
  * front and front-or-bring-up
  * bounds save/load/apply (NO onClose hooks)
- Known-good SC only; idempotent installs via isNil.if (no '??' auto-eval).
- Style: tilde vars, var-first, descriptive names, lowercase methods.
*/

(
var ensure;

("Running: LivePedalboardSystem_WindowManager_Install.scd").postln;

ensure = {
    // --- policy prefix
    ~lps_windowPrefix.isNil.if({
        ~lps_windowPrefix = "MagicDisplayGUI";
    });

    // --- find windows by prefix
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

    // --- close windows by prefix
    ~lps_closeWindowsByPrefix.isNil.if({
        ~lps_closeWindowsByPrefix = { |prefix|
            var windowsToClose, closedCount;
            windowsToClose = ~lps_findWindowsByPrefix.(prefix).copy; // avoid mutating while iterating
            closedCount = 0;
            windowsToClose.do({ |win|
                win.close;
                closedCount = closedCount + 1;
            });
            closedCount
        };
    });

    // --- bring up exactly one window via builder
    ~lps_bringUpSingleWindow.isNil.if({
        ~lps_bringUpSingleWindow = { |prefix, buildFunc, desiredTitle|
            var effectivePrefix, existing, windowTitle, createdWindow;
            effectivePrefix = prefix ?? { ~lps_windowPrefix };
            windowTitle = desiredTitle ?? { effectivePrefix };
            existing = ~lps_findWindowsByPrefix.(effectivePrefix);

            if(existing.size == 1) {
                createdWindow = existing.first;
                if(createdWindow.name.asString != windowTitle) { createdWindow.name = windowTitle };
                createdWindow.front;
                createdWindow
            } {
                // Close *all* of ours, then build fresh
                ~lps_closeWindowsByPrefix.(effectivePrefix);
                createdWindow = buildFunc.value(windowTitle);
                if(createdWindow.notNil and: { createdWindow.isKindOf(Window) }) {
                    createdWindow.name = windowTitle;
                    createdWindow.front;
                };
                createdWindow
            }
        };
    });

    // --- front existing (non-destructive)
    ~lps_frontByPrefix.isNil.if({
        ~lps_frontByPrefix = { |prefix|
            var effectivePrefix, wins;
            effectivePrefix = prefix ?? { ~lps_windowPrefix };
            wins = ~lps_findWindowsByPrefix.(effectivePrefix);
            wins.notEmpty.if({ wins.first.front; wins.first }, { nil })
        };
    });

    // --- front or bring-up
    ~lps_frontOrBringUpByPrefix.isNil.if({
        ~lps_frontOrBringUpByPrefix = { |prefix, buildFunc, desiredTitle|
            var effectivePrefix, win;
            effectivePrefix = prefix ?? { ~lps_windowPrefix };
            win = ~lps_frontByPrefix.(effectivePrefix);
            win.notNil.if({ win }, {
                ~lps_bringUpSingleWindow.(effectivePrefix, buildFunc, desiredTitle)
            })
        };
    });

    // --- bounds: prefs dir + file path
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

    // --- save bounds (guards for nils)
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

    // --- load bounds
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

    // --- apply bounds (guard: rect not nil)
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
)