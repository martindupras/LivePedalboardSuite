// LivePedalboardSystem-BringUpPedalboard.sc
// v0.1.0
// MD 20251006-1438

/* Purpose
   - Provide bringUpPedalboard for the currently loaded LivePedalboardSystem.
   Style
   - var-first; lowercase names; no server.sync; defensive checks; no non-local returns.
*/

+ LivePedalboardSystem {

    bringUpPedalboard {
        var klass, pb;

        // Find MagicPedalboard class defensively
        klass = \MagicPedalboard.asClass;
        if(klass.isNil) {
            "[LPS] MagicPedalboard class not found on classpath; skipping bringUpPedalboard."
            .warn;
            ^this;
        };

        // Construct, optionally wiring the display adapter if we have one
        pb = if(this.statusDisplay.notNil) {
            klass.new(this.statusDisplay)
        } {
            klass.new
        };

        if(this.statusDisplay.notNil and: { pb.respondsTo(\setDisplay) }) {
            pb.setDisplay(this.statusDisplay);
        };

        this.pedalboard = pb;       // store reference
        this.pedalboardGUI = nil;   // no runner GUI in the LPDisplay path

        " [LPS] MagicPedalboard initialized and bound to LPDisplay adapter."
        .postln;

        ^this
    }
}