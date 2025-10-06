// DEMO20250923_FIXED.scd
// v0.2.0
// MD 2025-09-23 10:46 BST

/* Purpose
 - Run the 2025-09-23 demo steps while updating MagicDisplayGUI at each step.
 - Uses ~nav_handleFret from the SimNav patch (Fix 1) so the GUI shows choices
   and "Apply → ..." on leaf selections.
Style
 - var-first; AppClock-only; no server.sync; one MagicDisplayGUI window.
*/

(
var steps, gap, i, runStep, schedNext;

if(~system.isNil) { "⚠️ Bring-up first: Start_LivePedalboardSystem.scd (Option B)".warn; ^nil };
if(~nav_handleFret.isNil) { "⚠️ Load SimNav_Bridge_ApplyLeafPayload_FIX.scd first".warn; ^nil };

// Your original script, now paced:
steps = [
    // Add delay → /add/delay
    { ~nav_handleFret.(6,10) }, // commands
    { ~nav_handleFret.(5, 1) }, // add
    { ~nav_handleFret.(4, 1) }, // delay (leaf → applies)

    // Switch → /switch
    { ~nav_handleFret.(6,10) }, // commands
    { ~nav_handleFret.(5, 3) }, // switch (leaf → applies)

    // Bypass delay ON
    { ~nav_handleFret.(6,10) }, // commands
    { ~nav_handleFret.(5, 2) }, // bypass
    { ~nav_handleFret.(4, 1) }, // delay
    { ~nav_handleFret.(3, 2) }, // on (leaf)

    // Bypass delay OFF
    { ~nav_handleFret.(6,10) },
    { ~nav_handleFret.(5, 2) },
    { ~nav_handleFret.(4, 1) },
    { ~nav_handleFret.(3, 3) }, // off (leaf)

    // Set source testmelody → /setSource/testmelody
    { ~nav_handleFret.(6,10) }, // commands
    { ~nav_handleFret.(5, 4) }, // setSource
    { ~nav_handleFret.(4, 1) }  // testmelody (leaf)
];

// pacing
gap = 0.55;
i = 0;
runStep = { steps[i].value; i = i + 1; if(i < steps.size) { schedNext.() } };
schedNext = { AppClock.sched(gap, { runStep.(); nil }) };

// kick off and ensure GUI is showing something
~nav_reset.();
AppClock.sched(0.0, { runStep.(); nil });
)
