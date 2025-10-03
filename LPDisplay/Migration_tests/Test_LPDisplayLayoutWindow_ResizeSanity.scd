// Test_LPDisplayLayoutWindow_ResizeSanity.scd
// v0.1.0
// MD 20251003-1110

/* Purpose/Style:
- Try a few window sizes and check all child views remain inside the content view.
- Posts warnings if any child bounds exceed the content area.
- Leaves the window at its original bounds; returns -> a Window.
*/

(
var createdWindow, originalBounds, testBoundsList, contentView, checkChildrenInside;

("Running: Test_LPDisplayLayoutWindow_ResizeSanity.scd").postln;

createdWindow = LPDisplayLayoutWindow.respondsTo(\open).if({
    LPDisplayLayoutWindow.open
}, {
    LPDisplayLayoutWindow.new
});

originalBounds = createdWindow.bounds;
contentView = createdWindow.view;

checkChildrenInside = { |parentView|
    var parentRect;
    parentRect = parentView.bounds;
    parentView.children.do({ |v|
        var b, inside;
        b = v.bounds; // bounds are relative to parent
        inside = (b.left >= 0) and: { b.top >= 0 } and: { (b.right <= parentRect.width) } and: { (b.bottom <= parentRect.height) };
        inside.if({
            // ok
        }, {
            ("WARN: Child " ++ v.class.name.asString ++ " bounds " ++ b.asString
             ++ " exceed parent size " ++ parentRect.asString).warn;
        });
    });
};

testBoundsList = [
    Rect(100, 100, originalBounds.width.max(360), originalBounds.height.max(240)),  // small but reasonable
    Rect(100, 100, (originalBounds.width * 1.2).round, (originalBounds.height * 1.2).round),
    Rect(100, 100, (originalBounds.width * 1.6).round, (originalBounds.height * 1.6).round)
];

testBoundsList.do({ |r|
    ("Resizing window to: " ++ r.asString).postln;
    createdWindow.bounds = r;
    AppClock.sched(0.05, { 0 }); // brief tick to let layout settle
    checkChildrenInside.(contentView);
});

// restore and front
createdWindow.bounds = originalBounds;
createdWindow.front;

// return -> a Window
createdWindow
)
