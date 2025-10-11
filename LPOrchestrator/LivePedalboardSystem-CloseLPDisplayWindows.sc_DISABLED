// LivePedalboardSystem-CloseLPDisplayWindows.sc
// v0.1.1
// MD 20251006-1752

/*
Purpose
- Provide LivePedalboardSystem>>closeExistingMagicDisplayWindows that closes LPDisplay windows.
- Add closeExistingLPDisplayWindows as the canonical method (both do the same).
Style
- var-first; no server.sync; descriptive names; no non-local returns.
*/

+ LivePedalboardSystem {

    // Back-compat entry point (your bringUp path is calling this)
    closeExistingMagicDisplayWindows {
        var selfRef;
        selfRef = this;
        selfRef.closeExistingLPDisplayWindows;
        ^selfRef
    }

    // Canonical closer: match ONLY LPDisplay windows
    closeExistingLPDisplayWindows {
        var windowsToClose, shouldClose;

        shouldClose = { arg w;
            var nameString;
            nameString = (w.name ? "").asString;
            (nameString.beginsWith("LPDisplay")) and: { w.isClosed.not }
        };

        windowsToClose = Window.allWindows.select(shouldClose);

        windowsToClose.do({ arg w;
            var wref;
            wref = w;
            if (wref.notNil and: { wref.isClosed.not }) {
                // avoid recursion if the window has onClose hooks
                wref.onClose = { };
                wref.close;
            };
        });

        ^this
    }
}