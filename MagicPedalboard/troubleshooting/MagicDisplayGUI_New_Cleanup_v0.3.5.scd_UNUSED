// MagicDisplayGUI_New_Cleanup_v0.3.5.scd
// v0.3.5
// MD timestamp: 2025-09-25

/* Purpose
   - Close GUI, free OSC receiver, clear server nodes/bus, and reset state.
   - Silent and idempotent: safe to run multiple times; no 'Node not found' noise.

   Style
   - var-first in every block; no non-local returns (^).
*/

(
var ok, hadServer;

ok = true;

// GUI
if (~mdGui_ticker.notNil) { ~mdGui_ticker.stop; ~mdGui_ticker = nil; };
if (~mdGui_window.notNil) { ~mdGui_window.close; ~mdGui_window = nil; };

// OSC receiver
if (OSCdef(\md_levels).notNil) { OSCdef(\md_levels).free; };

// Server nodes (only if server running)
hadServer = s.serverRunning;
if (hadServer) {
    s.bind({
        s.defaultGroup.freeAll;
    });
}

// Bus
if (~md_mixBus.notNil) { ~md_mixBus.free; ~md_mixBus = nil; };

// State
~levels = [0.0, 0.0];
~md_lastLevelAt = 0.0;
~md_testSynth = nil;
~md_probe = nil;
~md_toHardware = nil;
~md_srcGroup = nil;
~md_meterGroup = nil;
~md_outGroup = nil;

// ensure final expression is a simple boolean
true;
)
