// LivePedalboardSystem_Accessors.sc
// v0.2.0
// MD 20251003-1620

/* Purpose / Style
- Expose the real CommandManager for auto-bind:
  1) Return the ivar 'commandManager' if it looks like a CM (has updateDisplay + builder).
  2) Else, probe self.pedalboard.* under common names and return the first CM-like object.
- Aliases cmdManager/cm/manager delegate to commandManager.
- Style: var-first; lowercase; descriptive names; no server.sync.
*/

+LivePedalboardSystem {

    commandManager {
        var cmLocal, pb, candidates, found;

        // 1) Prefer the real ivar on this object (NOTE: do NOT write 'this.commandManager' here)
        cmLocal = commandManager;  // ivar access
        if(cmLocal.notNil and: { cmLocal.respondsTo(\updateDisplay) and: { cmLocal.respondsTo(\builder) } }) {
            ^cmLocal
        };

        // 2) Fallback: probe under pedalboard.* with common names
        pb = this.tryPerform(\pedalboard);
        if(pb.notNil) {
            candidates = [\commandManager, \cmdManager, \cm, \manager, \commandCenter, \commandCentre];
            found = candidates.detect({ arg sel;
                var cand = pb.tryPerform(sel);
                cand.notNil and: { cand.respondsTo(\updateDisplay) and: { cand.respondsTo(\builder) } }
            });
            if(found.notNil) { ^pb.perform(found) };
        };

        ^nil
    }

    cmdManager { ^this.commandManager }
    cm         { ^this.commandManager }
    manager    { ^this.commandManager }
}