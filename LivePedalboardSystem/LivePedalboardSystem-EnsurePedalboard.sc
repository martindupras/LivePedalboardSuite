// LivePedalboardSystem-EnsurePedalboard.sc
// v0.2.1
// MD 20251008-2056

/* Purpose
- Guarantee MagicPedalboard exists and sinks (\chainA/\chainB) are defined AR.
- Add bringUpAllSafe that wraps original bringUpAll and enforces checks.
*/

+ LivePedalboardSystem {

    ensurePedalboardExists {
        var created;
        created = false;

        if(this.pedalboard.isNil) {
            this.pedalboard = MagicPedalboard.new(this.statusDisplay ? nil);
            created = true;
        };

        this.ensureSinksDefined;

        this.tryPerform(\logInfo, "LPS", created.if({ "Pedalboard created." }, { "Pedalboard present." }));
        if(this.tryPerform(\lpDisplay).notNil) {
            this.lpDisplay.tryPerform(\sendPaneText, \system, created.if({ "PEDALBOARD CREATED" }, { "PEDALBOARD OK" }));
        };
        ^this
    }

    ensureSinksDefined {
        Ndef(\chainA, { var x; x = \in.ar(0!2); x }).ar(2);
        Ndef(\chainB, { var y; y = \in.ar(0!2); y }).ar(2);
        ^this
    }

    bringUpAllSafe {
        var win;
        win = this.bringUpAll;   // -> a Window
        this.ensurePedalboardExists;
        ^win
    }
}
