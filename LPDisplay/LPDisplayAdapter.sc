// LPDisplayAdapter.sc
// v1.1.0
// MD 20251003-1315

/* Purpose / Style
- Adapter so CommandManager.display.respondsTo(...) is true.
- Map legacy GUI calls to LPDisplay panes via controller.sendPaneText.
- Adds non-destructive highlightCurrentColumn -> Diag pane.
- Style: var-first; lowercase; no server.sync; descriptive names.
*/

LPDisplayAdapter {
    var controller;

    *new { arg controllerRef;  ^super.new.init(controllerRef) }

    init { arg controllerRef;
        controller = controllerRef;
        ^this
    }

    showExpectation { arg text, idx = 0;
        var msg = text.asString;
        if(controller.notNil) { controller.sendPaneText(\system, msg) };
        ^this
    }

    updateTextField { arg box, msg;
        var pane, target, txt;
        pane = box.asSymbol;
        txt  = msg.asString;
        target = (pane == \state).if({ \system }, { (pane == \choices).if({ \choices }, { \diag }) });
        if(controller.notNil) { controller.sendPaneText(target, txt) };
        ^this
    }

    setOperations { arg lines;
        var joined = ((lines ? []) collect: _.asString).join(Char.nl.asString);
        if(controller.notNil) { controller.sendPaneText(\choices, joined) };
        ^this
    }

    // NEW: non-destructive active-side indicator in Diag
    highlightCurrentColumn { arg which;
        var label = which.asString.toLower;
        var text  = (label.contains("a") or: { label.contains("current") })
            .if({ "Active chain: A" }, { "Active chain: B" });
        if(controller.notNil) { controller.sendPaneText(\diag, text) };
        ^this
    }

    enableMeters { arg flag = true; ^this }
}