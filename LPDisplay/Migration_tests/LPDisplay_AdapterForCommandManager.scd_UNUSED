// LPDisplay_AdapterForCommandManager.scd
// v0.2.0
// MD 20251003-1242

/* Purpose / Style
- Provide a small 'object' that CommandManager can treat as a display.
- Uses JITLib Proto so .respondsTo(\showExpectation) etc. return true.
- Maps old GUI calls to LPDisplay panes via ~guiLP.sendPaneText.
- Style: tilde vars; var-first; lowercase; no args starting with '_'; known-good SC syntax.
*/

(
var makeAdapter, toStringSafe;

toStringSafe = { arg obj; obj.asString };

makeAdapter = {
    var adapter;
    adapter = Proto({
        var self;

        ~showExpectation = { arg self, text, idx = 0;
            var t;
            t = toStringSafe.(text);
            (~guiLP.notNil).if({ ~guiLP.sendPaneText(\system, t) });
            nil
        };

        ~updateTextField = { arg self, box, msg;
            var pane, t, target;
            pane = box.asSymbol;
            t = toStringSafe.(msg);
            target = (pane == \state).if({ \system }, { (pane == \choices).if({ \choices }, { \diag }) });
            (~guiLP.notNil).if({ ~guiLP.sendPaneText(target, t) });
            nil
        };

        ~setOperations = { arg self, lines;
            var joined;
            joined = ((lines ? []) collect: { arg x; x.asString }).join(Char.nl.asString);
            (~guiLP.notNil).if({ ~guiLP.sendPaneText(\choices, joined) });
            nil
        };

        // legacy in tests (safe no-ops)
        ~highlightCurrentColumn = { arg self, which; nil };
        ~enableMeters          = { arg self, flag = true; nil };
    });

    ~lp_displayAdapter = adapter;

    // If the system is already up, bind immediately
    if(~system.notNil) {
        var cm = ~system.tryPerform(\commandManager);
        (cm.notNil).if({ cm.display = adapter });
    };

    "LPDisplay adapter ready (bound if ~system.commandManager exists).".postln;
    adapter
};

makeAdapter.();
)