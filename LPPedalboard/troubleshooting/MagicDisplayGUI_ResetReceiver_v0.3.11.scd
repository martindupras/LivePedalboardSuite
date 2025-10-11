// MagicDisplayGUI_ResetReceiver_v0.3.11.scd
// v0.3.11
// MD 2025-09-25 15:10 BST

/*
Purpose
- Reinstall the /md/levels receiver on NetAddr.langPort (idempotent).
- Posts identity banner so logs show exact order of actions.
Style
- var-first; no server.sync; returns -> true.
*/

(
// === RUN ===
var ok, dict;
dict = (~md_levelsById ? IdentityDictionary.new);
~md_levelsById = dict;
ok = ~md_reinstallReceiver !? { ~md_reinstallReceiver.() } ? false;
("Receiver reset: " ++ ok).postln;
true
) // -> true
