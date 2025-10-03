// LivePedalboardSystem_Accessors.sc
// v0.1.0
// MD 20251003-1552

/* Purpose / Style
- Provide a standard accessor `commandManager` on LivePedalboardSystem so external code
  (e.g. LPDisplay bring-up) can auto-bind without knowing internal ivar names.
- Strategy: try self.pedalboard.* under common CM names; return the first object that
  responds to \updateDisplay and \builder. Aliases (cmdManager/cm/manager) delegate to it.
- Style: var-first; lowercase method names; descriptive vars; no server.sync.
*/

+LivePedalboardSystem {

    commandManager {
        var pedalboardObj, candidates, result;
        pedalboardObj = this.tryPerform(\pedalboard);
        result = nil;

        if(pedalboardObj.notNil) {
            candidates = [\commandManager, \cmdManager, \cm, \manager];
            candidates.do({ arg sel;
                var candidate;
                candidate = pedalboardObj.tryPerform(sel);
                if(result.isNil and: {
                    candidate.notNil and: { candidate.respondsTo(\updateDisplay) and: { candidate.respondsTo(\builder) } }
                }) {
                    result = candidate;
                };
            });
        };

        ^result
    }

    cmdManager { ^this.commandManager }
    cm         { ^this.commandManager }
    manager    { ^this.commandManager }
}