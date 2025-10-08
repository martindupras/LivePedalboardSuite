// Test_VSCode_Eval.scd
// v0.1.0
// MD 20251008-1120

/*
Purpose: Sanity test that VS Code → sclang eval works, GUI starts, and returns -> a Window.
Style: var-first; one block; AppClock safe; returns -> a Window
*/

(
var win;
s.waitForBoot({
    Server.default.bind({
        s.initTree;
        s.defaultGroup.freeAll;
    });
});
win = Window("VSCode Eval OK", Rect(100, 100, 240, 120)).front;
win; // -> a Window
)
