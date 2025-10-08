// LivePedalboardSystem_AutoBindLPDisplay.sc
// v0.1.0
// MD 20251003-1630

/* Purpose / Style
- Add a minimal system-side auto-bind so that if an LPDisplay controller (~guiLP) is present,
  the system's CommandManager binds to LPDisplayAdapter automatically.
- It uses your fixed accessor (commandManager -> ivar first, pedalboard.* fallback).
- Style: var-first; lowercase; descriptive names; no server.sync; AppClock only in GUI classes.
*/

+LivePedalboardSystem {

    autoBindLPDisplayIfPresent {
        var controller, cm, adapter;

        // 1) require the LPDisplay controller from your bring-up block
        controller = ~guiLP;
        if(controller.isNil) { ^this };  // nothing to bind yet

        // 2) resolve the real CM via your accessor (ivar-first, then pedalboard.*)
        cm = this.commandManager;
        if(cm.isNil) { ^this };

        // 3) reuse existing adapter if available; else create a new one
        adapter = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(controller) });
        ~lp_adapter = adapter;

        // 4) bind once and refresh panes
        cm.display = adapter;
        cm.updateDisplay;

        // 5) optional durable note
        (~md_log.notNil).if({ ~md_log.("System-side auto-bind OK (LPDisplayAdapter)") });

        ^this
    }

    // optional wrapper: full bring-up then auto-bind
    bringUpAllWithLPDisplayAutoBind {
        var selfRef;
        selfRef = this.bringUpAll;
        this.autoBindLPDisplayIfPresent;
        ^selfRef
    }
}