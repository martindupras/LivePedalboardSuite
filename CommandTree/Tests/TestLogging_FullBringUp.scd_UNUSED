TestLogging_FullBringUp.scd
v0.1.0
MD 2025-09-22 09:52 BST

/*
Purpose
- See file comments for details.
Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/


(
var lps;
MDMiniLogger.get.setverbosity(2); // INFO

lps = LivePedalboardSystem.new(nil);
lps.bringUpAll;

// Switch to DEBUG if you want more detail for a moment
MDMiniLogger.get.setverbosity(3);

lps.commandManager.setStatus("Sanity check: status via MDMiniLogger");
)
