// LivePedalboardSystem_WindowManager_ReturnGuard.scd
// v0.1.0
// MD 20251003-1125

/* Purpose/Style:
- Patch the bring-up helper to ensure it always returns a Window when one exists.
- Minimal change: add a fallback lookup before returning.
*/

(
var originalFunc;

("Running: LivePedalboardSystem_WindowManager_ReturnGuard.scd").postln;

originalFunc = ~lps_bringUpSingleWindow;

~lps_bringUpSingleWindow = { |prefix, buildFunc, desiredTitle|
    var effectivePrefix, existing, windowTitle, createdWindow, fallbackWindow;

    effectivePrefix = prefix ?? { ~lps_windowPrefix };
    existing = ~lps_findWindowsByPrefix.(effectivePrefix);
    windowTitle = desiredTitle ?? { effectivePrefix };

    if(existing.size == 1) {
        createdWindow = existing.first;
        if(createdWindow.name.asString != windowTitle) {
            createdWindow.name = windowTitle;
        };
        createdWindow.front;
    }{
        ~lps_closeWindowsByPrefix.(effectivePrefix);
        createdWindow = buildFunc.value(windowTitle);
        if(createdWindow.notNil and: { createdWindow.isKindOf(Window) }) {
            createdWindow.name = windowTitle;
            createdWindow.front;
        };
    };

    // Fallback: if builder returned nil or a non-Window, try to pick up a window by prefix
    if(createdWindow.isNil or: { createdWindow.isKindOf(Window).not }) {
        fallbackWindow = ~lps_findWindowsByPrefix.(effectivePrefix).first;
        createdWindow = fallbackWindow;
    };

    createdWindow
};
)
