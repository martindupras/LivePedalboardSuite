// 02B_HUD_AB_StrictAOnly.scd
// v0.1.4
// MD 2025-09-29 13:05

/* Purpose
   - Force Chain A to display as ACTIVE with a solid, non-pulsing highlight.
   - Uses the HUD adapter if available (~hud_highlightCurrent), else tries GridDemo.
Style
   - var-first; AppClock UI; idempotent; no server.sync.
*/

(
var apply;

apply = {
    if(~hud_highlightCurrent.notNil) {
        ~hud_highlightCurrent.(\chainA);
        if(~hud_showExpectation.notNil) { ~hud_showExpectation.("HUD: Chain A ACTIVE (solid)", 0) };
    }{
        // Fallback for raw GridDemo controller if adapter missing
        if(~gui.notNil and: { ~gui.respondsTo(\highlightCurrentColumn) }) {
            ~gui.highlightCurrentColumn(\chainA);
            if(~gui.respondsTo(\showExpectation)) { ~gui.showExpectation("HUD: Chain A ACTIVE (solid)", 0) };
        }{
            "02B: No HUD adapter and no GridDemo methods; nothing to do.".warn;
        };
    };
};

AppClock.sched(0.0, { apply.value; nil });
)
