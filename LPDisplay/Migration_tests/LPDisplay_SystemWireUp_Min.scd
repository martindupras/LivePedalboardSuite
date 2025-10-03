// LPDisplay_SystemWireUp_Min.scd
// v0.1.1
// MD 20251003-1420

/* Purpose / Style
- Ensure ~system exists (LivePedalboardSystem.new if missing).
- Bind its CommandManager to LPDisplay via LPDisplayAdapter.
- Expose ~sys_nav_* helpers so you can navigate with the real system.
- Style: var-first; tilde vars; lowercase; descriptive names.
*/

(
var makeSystem, bindAdapterToSystem, exposeSysNav, cm;

makeSystem = {
    if(~system.isNil) {
        ~system = LivePedalboardSystem.new(nil);  // uses class defaults; no GUI windows needed here
    };
    ~system
};

bindAdapterToSystem = {
    var adapterLocal;
    cm = ~system.tryPerform(\commandManager);
    adapterLocal = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(~guiLP) });
    ~lp_adapter = adapterLocal;
    if(cm.notNil) {
        cm.display = adapterLocal;
        cm.updateDisplay;
        "System bound: CommandManager → LPDisplay (updateDisplay called).".postln;
    }{
        "Note: could not find ~system.commandManager.".warn;
    };
    cm
};

exposeSysNav = {
    ~sys_nav_show  = { var c = ~system.tryPerform(\commandManager); c.notNil.if({ c.updateDisplay }) };
    ~sys_nav_fret  = { arg fret; var c = ~system.tryPerform(\commandManager);
        c.notNil.if({ c.builder.navigateByFret(nil, fret); c.updateDisplay })
    };
    ~sys_nav_reset = { var c = ~system.tryPerform(\commandManager);
        c.notNil.if({ c.builder.resetNavigation; c.updateDisplay; "🔄 System navigation reset".postln })
    };
    nil
};

makeSystem.();
bindAdapterToSystem.();
exposeSysNav.();

(~lp_front.notNil).if({ ~lp_front.() });
)