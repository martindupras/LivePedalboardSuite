// MagicDisplayGUI_New_Cleanup_v0.3.1.scd
// v0.3.1
// MD timestamp: 2025-09-25

/* Purpose
   - Fast way to remove GUI, OSC receiver, synths, groups, bus; leave server running clean.
*/

(
var ok;

ok = true;

// GUI
if (~mdGui_ticker.notNil) { ~mdGui_ticker.stop; ~mdGui_ticker = nil; };
if (~mdGui_window.notNil) { ~mdGui_window.close; ~mdGui_window = nil; };

// Receiver
if (OSCdef(\md_levels).notNil) { OSCdef(\md_levels).free; };

// Synths
if (~md_testSynth.notNil) { ~md_testSynth.free; ~md_testSynth = nil; };
if (~md_probe.notNil) { ~md_probe.free; ~md_probe = nil; };
if (~md_toHardware.notNil) { ~md_toHardware.free; ~md_toHardware = nil; };

// Groups
if (~md_outGroup.notNil) { ~md_outGroup.free; ~md_outGroup = nil; };
if (~md_meterGroup.notNil) { ~md_meterGroup.free; ~md_meterGroup = nil; };
if (~md_srcGroup.notNil) { ~md_srcGroup.free; ~md_srcGroup = nil; };

// Bus
if (~md_mixBus.notNil) { ~md_mixBus.free; ~md_mixBus = nil; };

// State
~levels = [0.0, 0.0];
~md_lastLevelAt = 0.0;

s.defaultGroup.freeAll;

ok;
)
