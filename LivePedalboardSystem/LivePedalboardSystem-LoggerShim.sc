// LivePedalboardSystem-LoggerShim.sc
// v0.1.1
// MD 20251006-1848

/*
Purpose
- Ensure logger is initialized (MDMiniLogger) and provide safe log helpers.
- Avoids 'info not understood' on nil; falls back to postln if needed.

Style
- var-first; descriptive names; no server.sync; no non-local returns.
*/
// SH_suggestion
// wher does this get created?
// should be created  by misnamed livepedalboard system

//SH_suggestion
// looks like none of these methods  should be here
// logger should have nethods info, warn & error


+ LivePedalboardSystem {

    ensureLogger {
        var lg;
        if (logger.isNil) {
            // Prefer your MDMiniLogger singleton if present
            lg = MDMiniLogger.respondsTo(\get).if({ MDMiniLogger.get }, { nil });
            logger = lg;
            if (logger.notNil and: { logger.respondsTo(\verbosity_) }) {
                logger.verbosity_(2); // INFO
            };
        };
        ^this
    }

    logInfo { arg tag, msg;
        var lg, t, m;
        t = tag.asString; m = msg.asString;
        lg = logger ? (MDMiniLogger.respondsTo(\get).if({ MDMiniLogger.get }, { nil }));
        if (lg.notNil and: { lg.respondsTo(\info) }) {
            lg.info(t, m);
        }{
            // fallback
            ("[INFO] " ++ t ++ " — " ++ m).postln;
        };
        ^this
    }

    logWarn { arg tag, msg;
        var lg, t, m;
        t = tag.asString; m = msg.asString;
        lg = logger ? (MDMiniLogger.respondsTo(\get).if({ MDMiniLogger.get }, { nil }));
        if (lg.notNil and: { lg.respondsTo(\warn) }) {
            lg.warn(t, m);
        }{
            ("[WARN] " ++ t ++ " — " ++ m).postln;
        };
        ^this
    }

    logError { arg tag, msg;
        var lg, t, m;
        t = tag.asString; m = msg.asString;
        lg = logger ? (MDMiniLogger.respondsTo(\get).if({ MDMiniLogger.get }, { nil }));
        if (lg.notNil and: { lg.respondsTo(\error) }) {
            lg.error(t, m);
        }{
            ("[ERROR] " ++ t ++ " — " ++ m).postln;
        };
        ^this
    }
}