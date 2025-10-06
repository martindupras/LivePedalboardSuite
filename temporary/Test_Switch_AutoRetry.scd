// Test_Switch_AutoRetry.scd
// v0.1.1
// MD 20251006-1658

/*
Purpose
- Quietly exercise '/switch' via CM navigation, queue, and send with a tiny defer
  to avoid the short 'busy' window.
*/

(
var cm = ~lps.commandManager;

~toProg  = { cm.midiManager.setMode(cm.midiManager.modes[\prog]) };
~toQueue = { cm.midiManager.setMode(cm.midiManager.modes[\queue]) };
~toSend  = { cm.midiManager.setMode(cm.midiManager.modes[\send]) };
~nav     = { |string, fret| cm.builder.navigateByFret(string, fret); cm.updateDisplay };

// Navigation -> 'switch' (string 6, fret 5)
~toProg.();
~nav.(6, 5);

// Enqueue canonical "/switch"
~toQueue.();

// Send after 250 ms (avoid "busy")
AppClock.sched(0.25, { ~toSend.(); nil });
)