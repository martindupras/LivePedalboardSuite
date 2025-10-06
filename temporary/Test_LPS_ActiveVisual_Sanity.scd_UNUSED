// Test_LPS_ActiveVisual_Sanity.scd
// v0.1.0
// MD 20251004-1728

/* Purpose
- Guarantee ~system exists and is bound to LPDisplay.
- Force one ACTIVE/NEXT paint using setActiveChainVisual(\A|\B).
Style: var-first; tilde vars; no server.sync; AppClock for UI only.
*/

(
var ensureSystem, paintVisual, cm;

// 1) Ensure ~system is up and bound (non-destructive if it already exists)
ensureSystem = {
    if(~system.isNil) {
        ~system = LivePedalboardSystem.new(nil);
        ~system.ensureServerReady;
        ~system.bringUpPedalboard;
        ~system.bringUpCommandSystem;
        ~system.installAdapterBridge;
        "OK: ~system created and adapter bridge installed.".postln;
    }{
        "Reusing existing ~system.".postln;
    };
    ~system.autoBindLPDisplayIfPresent;   // idempotent
    cm = ~system.commandManager;
    cm.updateDisplay;
};

// 2) Paint ACTIVE/NEXT visual once using current chain (defaults to \A)
paintVisual = {
    var current = ~md_currentChain ? \A;
    var disp = ~system.tryPerform(\statusDisplay);
    if(disp.notNil) {
        if(disp.respondsTo(\setActiveChainVisual)) {
            disp.setActiveChainVisual(current);
            ("Painted ACTIVE=" ++ current).postln;
        }{
            "statusDisplay does not implement setActiveChainVisual (extension not loaded?)".warn;
        };
    }{
        "No statusDisplay on ~system (autoBind may have failed)".warn;
    };
};

// run
ensureSystem.();
paintVisual.();
"Sanity/repair complete.".postln;
)