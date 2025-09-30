//////////////////////////////////////////////////////////////
// 00A_HUD_Sanity_Check.scd
// v0.1.0
// MD 20250929-13:02

/* Purpose
   - Print which window(s) are open and what ~gui is.
Style
   - var-first; no server.sync; safe .tryPerform.
*/
(
var windowNames, guiClass, isWindow;

windowNames = Window.allWindows.collect({ |w| w.tryPerform(\name) ? "<unnamed>" });
guiClass = ~gui.tryPerform(\class);
isWindow = ~gui.notNil and: { ~gui.isKindOf(Window) };

"— HUD Sanity —".postln;
("Windows: " ++ windowNames).postln;
("~gui: " ++ (~gui ? "nil").asString).postln;
("~gui.class: " ++ (guiClass ? "nil").asString).postln;
("~gui is a Window? " ++ isWindow.asString).postln;
if(~gui.notNil) {
    ("GridDemo methods: highlight=" ++ ~gui.respondsTo(\highlightCurrentColumn)
      ++ " setOps=" ++ ~gui.respondsTo(\setOperations)).postln;
};
)
