// Bind_LPDisplayAdapter.scd
// v0.1.0
// MD 20251003-1252

/* Purpose / Style
- Create and bind the adapter so CommandManager writes into LPDisplay panes.
- Style: tilde vars; var-first; known-good SC syntax.
*/

(
var cm;
~lp_adapter = LPDisplayAdapter.new(~guiLP);
cm = (~system.notNil).if({ ~system.tryPerform(\commandManager) }, { nil });
(cm.notNil).if({ cm.display = ~lp_adapter });
"LPDisplayAdapter bound to CommandManager (if present).".postln;

// quick smoke
(~guiLP.notNil).if({ ~guiLP.sendPaneText(\system, "Adapter OK"); });
)
