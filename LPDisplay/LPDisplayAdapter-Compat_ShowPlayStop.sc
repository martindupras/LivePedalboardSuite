// LPDisplayAdapter-Compat_ShowPlayStop.sc
// v0.1.0
// MD 20251006-1612

/* Purpose
   - Compatibility shims for MagicDisplay API used by MagicPedalboard:
       showPlay(sinkKey)
       showStop(sinkKey)
   - Keep it minimal: update ACTIVE highlight and a short status line.
Style
   - var-first; lowercase names; AppClock for GUI updates; no server.sync; no non-local returns.
*/

+ LPDisplayAdapter {

    showPlay { arg sinkKey;
        var ctlr, which, label;
        ctlr  = controller;
        // Map sinkKey to \A or \B when possible
        which = case
            { sinkKey.asSymbol == \chainA } { \A }
            { sinkKey.asSymbol == \chainB } { \B }
            { true }                         { \A }; // conservative default

        // Update ACTIVE highlight and status text
        this.setActiveChainVisual(which);
        label = "PLAY " ++ which.asString;

        AppClock.sched(0.0, {
            if(ctlr.notNil) { ctlr.sendPaneText(\system, label) };
            nil
        });

        ^this
    }

    showStop { arg sinkKey;
        var ctlr, label;
        ctlr  = controller;
        label = "STOP " ++ sinkKey.asString;

        AppClock.sched(0.0, {
            if(ctlr.notNil) { ctlr.sendPaneText(\system, label) };
            nil
        });

        ^this
    }
}