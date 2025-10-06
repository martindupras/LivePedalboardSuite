// 02F_HUD_TestContent_StateChoicesIncoming.scd
// v0.1.3
// MD 2025-09-29 12:35

(
var gui, pushHUD;

gui = ~gui;

pushHUD = {
    var choicesLines;
    choicesLines = [
        "fret 3 → add",
        "fret 5 → timebased",
        "fret 7 → modulation",
        "fret 9 → filter"
    ];

    // Prefer GridDemo API
    if(gui.notNil and: { gui.respondsTo(\updateTextField) or: { gui.respondsTo(\showExpectation) } }) {
        if(gui.respondsTo(\updateTextField)) {
            gui.updateTextField(\state, "Mode: treeNav · A=ACTIVE");
        } {
            gui.showExpectation("Mode: treeNav · A=ACTIVE", 0);
        };
        if(gui.respondsTo(\setOperations)) {
            gui.setOperations(choicesLines);
        } {
            // fallback to status if no choices panel in that class
            gui.showExpectation("Choices:\n" ++ choicesLines.join("\n"), 0);
        };
    } {
        // PerfHUD + adapter
        if(~hud_updateTextField.notNil) {
            ~hud_updateTextField.(\state, "Mode: treeNav · A=ACTIVE");
        } { if(~hud_showExpectation.notNil) { ~hud_showExpectation.("Mode: treeNav · A=ACTIVE", 0) } };
        if(~hud_setOperations.notNil) {
            ~hud_setOperations.(choicesLines);
        } {
            if(~hud_showExpectation.notNil) {
                ~hud_showExpectation.("Choices:\n" ++ choicesLines.join("\n"), 0);
            };
        };
    };
};

AppClock.sched(0.0, { pushHUD.value; nil });
)
