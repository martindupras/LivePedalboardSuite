(
// Start_LivePedalboardSuite_BringUp_LPDisplay.scd
// v0.3.2
// MD 20251006-1600

/*
Purpose / Style
---------------
Starter script to bring up the LivePedalboardSystem with LPDisplay GUI.
- Relies on LivePedalboardSystem.bringUpAllWithLPDisplayAutoBind
- No manual GUI creation
- Returns -> a Window

Style:
- var-first declarations
- No non-local returns (^)
- AppClock only for GUI timing
- Known-good SuperCollider syntax only
*/

var livePedalboardSystem, lpDisplayController;

// Step 1 — Boot server and clean tree if needed
s.waitForBoot;
s.initTree;
s.defaultGroup.freeAll;
"[Start-LPDisplay] Server booted and tree initialized.".postln;

// Step 2 — Create and bring up LivePedalboardSystem (includes GUI + binding)
livePedalboardSystem = LivePedalboardSystem.new(nil);
livePedalboardSystem.bringUpAllWithLPDisplayAutoBind;
"[Start-LPDisplay] System bring-up and display binding completed.".postln;

// Step 3 — Retrieve display controller from system
lpDisplayController = livePedalboardSystem.statusDisplay;
"[Start-LPDisplay] Retrieved LPDisplay controller.".postln;

// Step 4 — Return GUI controller (required: -> a Window)
lpDisplayController
)
