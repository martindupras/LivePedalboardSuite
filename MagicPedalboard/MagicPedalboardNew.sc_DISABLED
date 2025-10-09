// MagicPedalboardNew.sc (DEPRECATED SHIM)
// v0.0.2 — shim subclass; warns at compile-time + first construction only
// MD 2025-10-02

MagicPedalboardNew : MagicPedalboard {
    classvar depWarnedAtRuntime;  // no accessor marker + no leading underscore

    *initClass {
        var msg;
        depWarnedAtRuntime = false;
        msg = "DEPRECATION: MagicPedalboardNew is now a shim. Use MagicPedalboard.";
        msg.warn;  // prints once per class library compile
    }

    // Warn once at first *construction* via MagicPedalboardNew in this process.
    *new { arg display = nil;
        var instance, msg;
        if (depWarnedAtRuntime.not) {
            msg = "DEPRECATION (runtime): MagicPedalboardNew was constructed. "
                ++ "Please migrate to MagicPedalboard.new(...).";
            msg.warn;
            depWarnedAtRuntime = true;
        };
        instance = super.new;
        ^instance.init(display)
    }
}
