// LPDisplayAdapter_SetChains.sc
// v0.1.0
// MD 20251006-1310

/* Purpose
- Allow CommandManager/LivePedalboardSystem to send chain label arrays to LPDisplay via adapter.
*/

+ LPDisplayAdapter {
    setChains { arg chainASyms, chainBSyms;
        var left, right;
        left = (chainASyms ? []).collect(_.asString).join(" → ");
        right = (chainBSyms ? []).collect(_.asString).join(" → ");
        if(controller.notNil) {
            controller.sendPaneText(\system, "");  // optional: clear stale message
            controller.sendPaneText(\left, left);
            controller.sendPaneText(\right, right);
        };
        ^this
    }
}