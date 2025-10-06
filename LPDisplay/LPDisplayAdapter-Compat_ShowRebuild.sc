// LPDisplayAdapter-Compat_ShowRebuild.sc
// v0.1.0
// MD 20251006-1540

/* Purpose
   - MagicPedalboard.rebuild(...) calls display.showRebuild(which, fullChain, effective).
   - Provide a minimal LPDisplay-compatible shim: write a concise line to the \diag pane.
   Style
   - var-first; AppClock for GUI; no server.sync; no non-local returns.
*/

+ LPDisplayAdapter {

    showRebuild { arg which, fullChain, effective;
        var ctlr, list, label, text;
        ctlr  = controller;
        // Prefer the "effective" chain if present; else the fullChain argument
        list  = (effective ? fullChain) ? [];
        label = which.asString; // typically 'current' or 'next'
        text  = (list.collect(_.asString)).join(" → ");

        AppClock.sched(0.0, {
            if(ctlr.notNil) {
                ctlr.sendPaneText(\diag, "rebuild(" ++ label ++ "): " ++ text);
            };
            nil
        });

        ^this
    }
}
