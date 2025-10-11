/*
 Simple smoke test for LPPedalboard.

 - Assumes the `LPPedalboard` class is already compiled/loaded in the IDE.
 - Instantiates one LPPedalboard, tries to select chain A (with a few
   reasonable selector fallbacks), plays current chain, and stops after 3s.

 Usage: open in the SC IDE and evaluate the buffer (or paste into the Post window).
*/

(
    var s = Server.default;
    s.waitForBoot({
        var lp = LPPedalboard.new;

        // Try a few common selectors to choose chain 'A' (use whichever exists)
        var selected = false;
        lp.respondsTo(\activateChain).ifTrue({ lp.activateChain(\A); selected = true });
        lp.respondsTo(\selectChain).ifTrue({ lp.selectChain(\A); selected = true });
        lp.respondsTo(\setCurrentChain).ifTrue({ lp.setCurrentChain(\A); selected = true });

        selected.ifFalse({ "No chain-selection API found on LPPedalboard; ensure chain A is active manually.".postln });

        // Play the current chain (common API)
        lp.respondsTo(\playCurrent).ifTrue({ lp.playCurrent }, { "playCurrent not found on LPPedalboard".postln });

        // Stop after 3 seconds if stopCurrent exists
        AppClock.sched(3.0, { lp.respondsTo(\stopCurrent).ifTrue({ lp.stopCurrent }) });
    });
)
