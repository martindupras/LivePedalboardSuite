// LPDisplayAdapter-Compat_ShowInit.sc
// v0.1.0
// MD 20251006-1452

/* Purpose
   - Provide MagicDisplay compatibility for MagicPedalboard.init(...),
     which calls display.showInit(pedalboard, versionString, current, next).
   Style
   - var-first; lowercase methods; AppClock for GUI updates; no server.sync.
*/

+ LPDisplayAdapter {

    showInit { arg pedalboard, versionString, current, next;
        var ctlr, left, right, active;

        ctlr = controller;

        // Build simple chain strings from the arrays MagicPedalboard passes in
        left  = (current ? []).collect(_.asString).join(" → ");
        right = (next    ? []).collect(_.asString).join(" → ");

        // Try to get the active side from the pedalboard; fall back to \A
        active = pedalboard.tryPerform(\currentKey) ? \A;

        // Push texts + ACTIVE highlight to LPDisplay on AppClock
        AppClock.sched(0.0, {
            if(ctlr.notNil) {
                ctlr.sendPaneText(\system, "MagicPedalboard " ++ versionString.asString);
                ctlr.sendPaneText(\left,  left);
                ctlr.sendPaneText(\right, right);
            };
            // use the adapter's forwarder to the controller
            this.setActiveChainVisual(active);
            nil
        });

        ^this
    }
}