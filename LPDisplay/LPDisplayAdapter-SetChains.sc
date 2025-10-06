// LPDisplayAdapter-SetChains.sc
// v0.1.0
// MD 20251006-1625

+ LPDisplayAdapter {
    setChains { arg chainASyms, chainBSyms;
        var left, right, ctlr;
        ctlr  = controller;
        left  = (chainASyms ? []).collect(_.asString).join(" → ");
        right = (chainBSyms ? []).collect(_.asString).join(" → ");
        AppClock.sched(0.0, {
            if(ctlr.notNil) {
                ctlr.sendPaneText(\left,  left);
                ctlr.sendPaneText(\right, right);
            };
            nil
        });
        ^this
    }
}