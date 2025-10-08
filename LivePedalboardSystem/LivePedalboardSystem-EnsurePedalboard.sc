// LivePedalboardSystem-EnsurePedalboard.sc
// v0.2.0
// MD 20251008-2034

/* Purpose
- Guarantee MagicPedalboard + sinks exist and report status during bring-up.
- Adds bringUpAllSafe so callers can opt into strict checks immediately.
*/

+ LivePedalboardSystem {

    ensurePedalboardExists {
        var made;
        made = false;

        if(this.pedalboard.isNil) {
            this.pedalboard = MagicPedalboard.new(this.statusDisplay ? nil);
            made = true;
        };

        this.ensureSinksDefined;

        this.tryPerform(\logInfo, "LPS", made.if({ "Pedalboard created." }, { "Pedalboard present." }));
        if(this.tryPerform(\lpDisplay).notNil) {
            this.lpDisplay.tryPerform(\sendPaneText, \system, made.if({ "PEDALBOARD CREATED" }, { "PEDALBOARD OK" }));
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
        win = this.bringUpAll;     // -> a Window (original behavior)
        this.ensurePedalboardExists;
        ^win
    }
}