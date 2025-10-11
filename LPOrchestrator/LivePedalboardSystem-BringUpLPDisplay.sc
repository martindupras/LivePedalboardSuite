// LivePedalboardSystem-BringUpLPDisplay.sc
// v0.1.0
// MD 20251006-1420

/* Purpose
   - Provide a dedicated bring-up that uses LPDisplay (controller + adapter)
     and returns -> a Window, without touching your existing bringUpAll.
   Style
   - var-first; Server.default.bind for server ops; AppClock for GUI; no server.sync.
*/

+ LivePedalboardSystem {

    bringUpLPDisplay {
        var win;

        // 1) Open LPDisplay controller/window
        this.lpDisplay = LPDisplayLayoutWindow.new;
        win = this.lpDisplay.open;  // -> a Window

        // 2) Install adapter so CommandManager.display calls map to LPDisplay panes
        this.statusDisplay = LPDisplayAdapter.new(this.lpDisplay);

        // 3) (Optional) HUD mapping and quieter console for meters
        this.lpDisplay.setHudMap(LPDisplayHudMap.new(-6, -60, 1.0));
        this.lpDisplay.setConsoleLevelsOn(false);

        // 4) Front the window and return it
        AppClock.sched(0.0, { win.front; nil });
        ^win
    }
}