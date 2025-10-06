// LPDisplayAdapter-Compat_ShowMutation.sc
// v0.1.0
// MD 20251006-1558

/* Purpose
   - MagicPedalboard sometimes calls display.showMutation(action, args, nextChain).
   - Provide a minimal LPDisplay-compatible shim:
       • Write an informative line to the \diag pane.
       • If nextChain begins with \chainA or \chainB, update that side’s chain text.
   Style
   - var-first; AppClock.defer scheduling; no server.sync; lowercase names; no non-local returns.
*/

+ LPDisplayAdapter {

    showMutation { arg action, args, nextChain;
        var ctlr, a, list, side, text, diagLine;

        ctlr = controller;
        a    = (args ? []).asArray;
        list = (nextChain ? []).asArray;
        side = (list.size > 0).if({ list[0] }, { nil }); // typically \chainA or \chainB
        text = list.collect(_.asString).join(" → ");
        diagLine = "mutation: " ++ action.asString
            ++ (a.isEmpty.if({ "" }, { "(" ++ a.collect(_.asString).join(", ") ++ ")" }));

        AppClock.sched(0.0, {
            if(ctlr.notNil) {
                // 1) Post an informative message in the diag pane
                ctlr.sendPaneText(\diag, diagLine);

                // 2) If we can infer which chain, update that side’s label
                if(side == \chainA) { ctlr.sendPaneText(\left,  text) };
                if(side == \chainB) { ctlr.sendPaneText(\right, text) };
            };
            nil
        });

        ^this
    }
}