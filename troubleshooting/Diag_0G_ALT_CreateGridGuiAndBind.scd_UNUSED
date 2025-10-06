// Diag_0G_ALT_CreateGridGuiAndBind.scd
// v0.1.0
// MD 2025-09-26 17:25 BST
/* Purpose / Style
   Purpose: Avoid the PerfHUD 'base_' crash by bringing up the GridDemo GUI instead.
            Bind CommandManager.display to the created GUI object and return → a Window.
   Style:   var-first; descriptive lowercase variable names; no server.sync; single MagicDisplayGUI window.
*/

(
var system_ref, cmd_mgr, gui_obj, window_list, gui_window;

system_ref = ~system;
if(system_ref.isNil) {
    // Construct LivePedalboardSystem with default path resolver (nil) and do the standard bring-up
    ~system = LivePedalboardSystem.new(nil);
    ~system.bringUpAll;  // server + pedalboard + command system (GUI may still be nil if PerfHUD crashed earlier)
};

// Close any existing MagicDisplayGUI windows to avoid duplicates
~system.closeExistingMagicDisplayWindows;

// Explicitly create the safe GridDemo GUI (bypass PerfHUD file loading)
gui_obj = MagicDisplayGUI_GridDemo.new;  // known-good fallback window class in your codebase

// Bind CommandManager.display if needed
cmd_mgr = ~system.commandManager;
if(cmd_mgr.notNil and: { cmd_mgr.display.isNil }) {
    cmd_mgr.display = gui_obj;
    "MD0G_ALT: bound CommandManager.display to GridDemo".postln;
};

// Bring the MagicDisplayGUI window to front and RETURN it
window_list = Window.allWindows;
gui_window = window_list.detect({ arg w;
    var title_string;
    title_string = w.tryPerform(\name);
    title_string.notNil and: { title_string.asString.beginsWith("MagicDisplayGUI") }
});
if(gui_window.notNil) { gui_window.front };
gui_window  // → a Window (final expression)
)
