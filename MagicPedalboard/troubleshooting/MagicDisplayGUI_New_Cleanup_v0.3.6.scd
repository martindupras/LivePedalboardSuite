// MagicDisplayGUI_New_Cleanup_v0.3.6.scd
// v0.3.6
// MD timestamp: 2025-09-25

/* Purpose
   - Close MagicDisplayGUI windows, stop GUI ticker, free OSC receiver.
   - Clear server default group (if running), free private bus, reset state vars.
   - Silent and idempotent; final expression is 'true' (never returns a Window).

   Style
   - var-first in every block; no non-local returns (^).
   - descriptive lowercase names; known-good SC syntax.
*/

(
var ok, hadServer, windows, i, w, nameString;

ok = true;

// stop GUI ticker if present
if (~mdGui_ticker.notNil) {
    ~mdGui_ticker.stop;
    ~mdGui_ticker = nil;
};

// close any MagicDisplayGUI windows (explicitly; this does not return the window)
windows = Window.allWindows;
i = 0;
while { i < windows.size } {
    w = windows[i];
    nameString = w.name.asString;
    if (nameString.beginsWith("MagicDisplayGUI")) {
        w.close;
    };
    i = i + 1;
};

// free OSC receiver if present
if (OSCdef(\md_levels).notNil) {
    OSCdef(\md_levels).free;
};

// clear server nodes (only if server is running)
hadServer = s.serverRunning;
if (hadServer) {
    s.bind({
        s.defaultGroup.freeAll;
    });
};

// free private bus if allocated
if (~md_mixBus.notNil) {
    ~md_mixBus.free;
    ~md_mixBus = nil;
};

// nil any cached node/bus references
~md_testSynth = nil;
~md_probe = nil;
~md_toHardware = nil;
~md_srcGroup = nil;
~md_meterGroup = nil;
~md_outGroup = nil;

// reset shared state
~levels = [0.0, 0.0];
~md_lastLevelAt = 0.0;

// final value: simple boolean (prevents '-> a Window')
true;
)
