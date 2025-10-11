// LivePedalboardSystem-CloseMagicDisplayWindows.sc
// v0.1.0
// MD 20251006-1732

/* Purpose
   - Provide LivePedalboardSystem>>closeExistingMagicDisplayWindows
   - Closes any open MagicDisplay windows so bringUpMagicDisplayGUI can start from a clean slate.

   Style
   - var-first; no server.sync; descriptive names; no non-local returns.
*/

+ LivePedalboardSystem {

    closeExistingMagicDisplayWindows {
        var windowsToClose, shouldClose;

        shouldClose = { arg w;
            var nameString;
            nameString = (w.name ? "").asString;
            // Recognize canonical and legacy titles
            (nameString.beginsWith("MagicDisplayGUI")
                or: { nameString == "Layout Test" }
                or: { nameString.beginsWith("LPDisplay") })
            and: { w.isClosed.not }
        };

        windowsToClose = Window.allWindows.select(shouldClose);

        windowsToClose.do({ arg w;
            // Make closure var-first inside to keep our style consistent
            var winToClose;
            winToClose = w;
            if (winToClose.notNil and: { winToClose.isClosed.not }) {
                // Prevent recursive callbacks if any onClose logic exists
                winToClose.onClose = { };
                winToClose.close;
            };
        });

        ^this
    }
}