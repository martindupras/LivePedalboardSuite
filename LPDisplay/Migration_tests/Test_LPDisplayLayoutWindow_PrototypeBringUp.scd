// Test_LPDisplayLayoutWindow_PrototypeBringUp.scd
// v0.1.0
// MD 20251003-1055

/* Purpose/Style:
- Prototype bring-up for LPDisplayLayoutWindow with minimal assumptions.
- Closes any existing LPDisplayLayoutWindow instances, opens a fresh one, and returns it (-> a Window).
- Known-good syntax; var-first; descriptive names; no single-letter locals; AppClock not required.
*/

(
var wantServerBoot, closedCount, openSelector, createdWindow, windowTitle, closeExisting;

wantServerBoot = false; // set true only if your window expects a running server
windowTitle = "LPDisplayLayoutWindow";

// Close any existing windows whose names begin with our title
closeExisting = {
    var survivors, nameMatches;
    survivors = List.new;
    Window.allWindows.do({ |w|
        nameMatches = w.notNil and: {
            var n;
            n = w.name;
            n.notNil and: { n.asString.beginsWith(windowTitle) }
        };
        if(nameMatches) { w.close } { survivors.add(w) };
    });
    survivors.size // not used, but keeps return; satisfies var-first discipline
};

closedCount = closeExisting.value;

// Boot server only if explicitly asked (UI-only window should not require it)
wantServerBoot.if({
    s = Server.default;
    s.waitForBoot({ /* no server ops needed for UI-only bring-up */ });
});

// Choose .open if present, otherwise .new
openSelector = LPDisplayLayoutWindow.respondsTo(\open).if({ \open }, { \new });

// Construct the window
createdWindow = LPDisplayLayoutWindow.perform(openSelector);
createdWindow.front;

// If the class didn’t set a name/title, enforce a stable title
(createdWindow.notNil and: {
    var existingTitle;
    existingTitle = createdWindow.name;
    existingTitle.isNil or: { existingTitle.asString.size == 0 }
}).if({
    createdWindow.name = windowTitle;
});

// Console hints
("Closed " ++ closedCount.asString ++ " existing '" ++ windowTitle ++ "' windows.").postln;
("Opened: " ++ createdWindow.name.asString).postln;

// Acceptance: return the window so SC prints '-> a Window'
createdWindow
)
