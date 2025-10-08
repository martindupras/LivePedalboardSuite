// MagicPedalboard-ReadyShim.sc
// v0.1.0
// MD 20251006-1839

/*
Purpose
- Provide missing methods startReadyPoll and stopReadyPoll so MagicPedalboard.init doesn't fail.
- Keep semantics simple and safe: mark the instance as 'ready' immediately and (optionally) notify display.
- No AppClock state is kept (no new ivars in extension), no server.sync, silent by default.

Style
- var-first; descriptive names; no non-local returns.
*/

+ MagicPedalboard {

    startReadyPoll { arg everySeconds = 0.25, timeoutSeconds = 8.0;
        var msg;
        // Minimal, conservative behaviour: declare the board ready now.
        ready = true;

        // Inform LPDisplay (harmless if no display wired yet)
        msg = "READY";
        this.display.tryPerform(\sendPaneText, \system, msg);

        ^this
    }

    stopReadyPoll {
        // No scheduled poll in this shim; nothing to stop.
        ^this
    }
}