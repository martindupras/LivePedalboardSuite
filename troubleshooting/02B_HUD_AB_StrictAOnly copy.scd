// 02B_HUD_AB_StrictAOnly.scd
// v0.1.3
// MD 20250929-1153

(
var gui, applySolidA;

gui = ~gui;

applySolidA = {
    // Prefer GridDemo API if present
    if(gui.notNil and: { gui.respondsTo(\highlightCurrentColumn) }) {
        gui.highlightCurrentColumn(\chainA);
        if(gui.respondsTo(\showExpectation)) {
            gui.showExpectation("HUD: Chain A ACTIVE (solid)", 0);
        };
    } {
        // PerfHUD + adapter
        if(~hud_highlightCurrentColumn.notNil) {
            ~hud_highlightCurrentColumn.(\chainA);
            if(~hud_showExpectation.notNil) {
                ~hud_showExpectation.("HUD: Chain A ACTIVE (solid)", 0);
            };
        } {
            "02B: No HUD adapter (~hud_*) and no GridDemo methods; nothing to do.".warn;
        };
    };
};

AppClock.sched(0.0, { applySolidA.value; nil });
)
