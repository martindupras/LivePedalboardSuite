// Test_LPDisplayLayoutWindow_Basics.scd
// v0.1.0
// MD 20251003-1110

/* Purpose/Style:
- Construct the window via .open if present, else .new.
- Verify it is a Window, bring it to front, and return it (-> a Window).
- Post a few basic properties without mutating the class.
*/

(
var createdWindow, ctorName, hasOpen, isWindow;

("Running: Test_LPDisplayLayoutWindow_Basics.scd").postln;

hasOpen = LPDisplayLayoutWindow.respondsTo(\open);
ctorName = hasOpen.if({ "open" }, { "new" });
createdWindow = hasOpen.if({ LPDisplayLayoutWindow.open }, { LPDisplayLayoutWindow.new });

isWindow = createdWindow.notNil and: { createdWindow.isKindOf(Window) };

("LPDisplayLayoutWindow constructor used: " ++ ctorName).postln;
("createdWindow is Window: " ++ isWindow.asString).postln;

isWindow.if({
    ("window name: " ++ (createdWindow.name ? "<nil>")).postln;
    ("window bounds: " ++ createdWindow.bounds.asString).postln;
    createdWindow.front;
}, {
    "Issue: LPDisplayLayoutWindow did not return a Window.".warn;
});

// Return the window so SC prints '-> a Window'
createdWindow
)