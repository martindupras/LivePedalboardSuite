// LPDisplayAdapter-Compat_ShowSwitch.sc
// v0.1.0
// MD 20251006-1713

/* Purpose
   - Legacy MagicDisplay call used by MagicPedalboard: showSwitch(oldSink, newSink, current, next)
   - Provide a concise LPDisplay adaptation:
       • Update ACTIVE highlight to the new sink.
       • Push short status text.
       • Update left/right chain labels from the 'current' and 'next' lists.
   Style
   - var-first; AppClock for GUI updates; no server.sync; lowercase; no non-local returns.
*/

+ LPDisplayAdapter {

    showSwitch { arg oldSink, newSink, currentList, nextList;
        var ctlr, which, leftText, rightText;

        ctlr = controller;

        // Map the new sink (\chainA or \chainB) to ACTIVE side
        which = case
            { newSink.asSymbol == \chainA } { \A }
            { newSink.asSymbol == \chainB } { \B }
            { true }                         { \A };

        // Build simple chain labels from arrays (e.g. [\chainA, \testmelody])
        leftText  = (currentList ? []).collect(_.asString).join(" → ");
        rightText = (nextList    ? []).collect(_.asString).join(" → ");

        // Update ACTIVE + panes + status on AppClock
        AppClock.sched(0.0, {
            if(ctlr.notNil) {
                this.setActiveChainVisual(which);
                ctlr.sendPaneText(\left,  leftText);
                ctlr.sendPaneText(\right, rightText);
                ctlr.sendPaneText(\system, "SWITCH " ++ which.asString);
            };
            nil
        });

        ^this
    }
}
