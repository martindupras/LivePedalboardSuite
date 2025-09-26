// Test_MagicDisplayGUI_BootAndScenarios.scd
// v0.1.6
// MD 2025-09-26 11:58 BST

/* Purpose / Style
   One-click system bring-up using the PerfHUD v0.5.4 integration:
   - LivePedalboardSystem.new(nil).bringUpAll() -> your PerfHUD window (v0.5.4).
   - Install queue->MPB adapter bridge (if present) and inline AutoMeters taps.
   - AppClock-only; var-first in EVERY block; no server.sync; generated audio only.
   - Final expression returns -> a Window.
*/

(
var systemRef, pickedWindow, wins;

// Fresh system
systemRef = LivePedalboardSystem.new(nil);
~system = systemRef;  // convenience handle at top level (allowed per your style)
systemRef.bringUpAll;

// Optional: adapter and inline meter taps
if(systemRef.respondsTo(\installAdapterBridge)) { systemRef.installAdapterBridge };
if(systemRef.respondsTo(\enableAutoMeters))     { systemRef.enableAutoMeters(18, 0.35) };

// Find MagicDisplay window produced by PerfHUD v0.5.4
wins = Window.allWindows;
pickedWindow = wins.detect({ arg w;
    var titleString;
    titleString = w.tryPerform(\name);
    titleString.notNil and: { titleString.asString.beginsWith("MagicDisplayGUI") }
});

// Final expression -> a Window
pickedWindow ? { wins.last }
)
