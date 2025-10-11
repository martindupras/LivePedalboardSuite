// BringUpSIMPLEST_LivePedalboardSystem.scd
// v0.0.1
// MD 20251008-1414

/* Purpose
- Simplest possible script to instantiate LivePedalboardSystem and open LPDisplay.
Style
- Single block; var-first; descriptive lowercase names; no server.sync.
- GUI actions on AppClock; returns '-> a Window'.
*/

(
var lpbSystem, displayWindow;

lpbSystem = LivePedalboardSystem.new;
displayWindow = lpbSystem.bringUpAll; // handles server readiness, GUI, meters, etc.

AppClock.sched(0.0, { var nothing; displayWindow.front; nil });
displayWindow
)
