//////////////////////////////////////////////////////////////
// 02F_HUD_TestContent_StateChoicesIncoming.scd
// v0.1.2
// MD 20250929-1120

/* Purpose
 - Write demo text to the HUD (state / choices / incoming).
 - Uses the public GridDemo API: showExpectation/updateTextField/setOperations.
Style
 - var-first, AppClock for UI, no server.sync, nil-safe responders.
*/

(
var gui, pushStateAndChoices;

gui = ~gui; // should be set by your earlier HUD bring-up step

if(gui.isNil) { "02F_HUD: ~gui is nil (skipping).".warn; ^nil; };

pushStateAndChoices = {
    // 0) (Optional) ensure the Choices panel exists (extension is nil-safe)
    if(gui.respondsTo(\ensureChoicesPanel)) { gui.ensureChoicesPanel };

    // 1) Top status / state line
    if(gui.respondsTo(\updateTextField)) {
        gui.updateTextField(\state, "Mode: treeNav · A=ACTIVE");
    } {
        if(gui.respondsTo(\showExpectation)) {
            gui.showExpectation("Mode: treeNav · A=ACTIVE", 0);
        };
    };

    // 2) Choices list (each line = “fret → name”)
    if(gui.respondsTo(\setOperations)) {
        gui.setOperations([
            "fret 3 → add",      // example entries; replace with your actual current node’s options
            "fret 5 → timebased",
            "fret 7 → modulation",
            "fret 9 → filter"
        ]);
    };

    // 3) “Incoming” (GridDemo doesn’t have a dedicated box; use status line)
    if(gui.respondsTo(\showExpectation)) {
        gui.showExpectation("Incoming: demo-key:a · demo-key:r", 0);
    };
};

// Defer to AppClock for UI safety
AppClock.sched(0.0, { pushStateAndChoices.value; nil });
)
