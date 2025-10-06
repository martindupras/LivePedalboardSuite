// Start_LPS_with_LPDisplay.scd
// v0.1.3
// MD 20251006-1657

/*
Purpose
- Full bring-up: server, LPDisplay window (-> a Window), MagicPedalboard, CommandManager,
  bridge, auto-meters, generated (silent) test source, and default MUTE ON (post-meter).
Style
- Single () block; var-first; Server.default.bind; AppClock for GUI; no server.sync.
- Returns -> a Window; stores ~lps so you can call helpers afterward.
*/

(
var win;

// Close stray MagicDisplay windows
Window.allWindows
.select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") or: { w.tryPerform(\name) == "Layout Test" } })
.do(_.close);

// 1) Build / boot / wipe
~lps = LivePedalboardSystem.new(nil);
~lps.ensureServerReady;

// 2) LPDisplay (controller + adapter) -> a Window
win = ~lps.bringUpLPDisplay; // -> a Window

// 3) Engine + command system + bridge + meters + audio graph (silent)
~lps.bringUpPedalboard;
~lps.bringUpCommandSystem;
~lps.installAdapterBridge;
~lps.enableAutoMeters(24, 0.35);
~lps.ensureAudioOn;

// 4) Default: MUTE ON (post-meter), meters still move
~muteAudio.();

// 5) Populate left/right panes + ACTIVE
~lps.refreshDisplay;

// 6) Return window
win
)