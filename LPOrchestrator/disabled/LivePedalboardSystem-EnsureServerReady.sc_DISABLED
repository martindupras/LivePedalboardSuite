// LivePedalboardSystem-EnsureServerReady.sc
// v0.1.0
// MD 20251006-1405

/* Purpose
   - Provide the missing ensureServerReady method as a small class extension.
   Style
   - var-first; no server.sync except s.waitForBoot on first boot; Server.default.bind for server ops.
*/

+ LivePedalboardSystem {
    ensureServerReady {
        var s, didBoot;
        s = Server.default;
        didBoot = false;

        if (s.serverRunning.not) {
            s.boot;
            s.waitForBoot; // allowed in your safe-reset pattern
            didBoot = true;
        };

        if (didBoot) {
            Server.default.bind({
                s.initTree;
                s.defaultGroup.freeAll;
            });
        };

        ^didBoot
    }
}