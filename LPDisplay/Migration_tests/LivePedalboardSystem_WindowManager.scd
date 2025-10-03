// LivePedalboardSystem_WindowManager.scd
// v0.1.0
// MD 20251003-1028

/* Purpose/Style:
- Utilities to enforce a single GUI window for LivePedalboardSystem.
- Default prefix is "MagicDisplayGUI"; you can override per call.
- Style: tilde vars, var-first, descriptive names, no single-letter locals.
*/

(
var ensureDefaults;

("Running: LivePedalboardSystem_WindowManager.scd").postln;

ensureDefaults = {
    ~lps_windowPrefix = ~lps_windowPrefix ?? { "MagicDisplayGUI" };

    ~lps_findWindowsByPrefix = ~lps_findWindowsByPrefix ?? { |prefix|
        var effectivePrefix, matchingWindows;
        effectivePrefix = prefix ?? { ~lps_windowPrefix };
        matchingWindows = Window.allWindows.select({ |win|
            var windowName;
            windowName = win.name.asString;
            windowName.notNil and: { windowName.beginsWith(effectivePrefix) }
        });
        matchingWindows
    };

    ~lps_closeWindowsByPrefix = ~lps_closeWindowsByPrefix ?? { |prefix|
        var windowsToClose, closedCount;
        windowsToClose = ~lps_findWindowsByPrefix.(prefix).copy; // copy to avoid modifying during iteration
        closedCount = 0;
        windowsToClose.do({ |win|
            win.close;
            closedCount = closedCount + 1;
        });
        closedCount
    };

    ~lps_bringUpSingleWindow = ~lps_bringUpSingleWindow ?? { |prefix, buildFunc, desiredTitle|
        var effectivePrefix, existing, windowTitle, createdWindow;

        effectivePrefix = prefix ?? { ~lps_windowPrefix };
        existing = ~lps_findWindowsByPrefix.(effectivePrefix);

        // Determine title we want to enforce; default to the prefix itself
        windowTitle = desiredTitle ?? { effectivePrefix };

        // Reuse if exactly one exists; otherwise close all and build fresh
        if(existing.size == 1) {
            createdWindow = existing.first;
            // normalize the title if different
            if(createdWindow.name.asString != windowTitle) {
                createdWindow.name = windowTitle;
            };
            createdWindow.front;
            createdWindow
        } {
            // remove strays and create a single window via builder
            ~lps_closeWindowsByPrefix.(effectivePrefix);

            // buildFunc must return a Window; we pass the title
            createdWindow = buildFunc.value(windowTitle);

            // ensure title and visibility
            if(createdWindow.notNil and: { createdWindow.isKindOf(Window) }) {
                createdWindow.name = windowTitle;
                createdWindow.front;
            };
            createdWindow
        }
    };
};

ensureDefaults.();
)