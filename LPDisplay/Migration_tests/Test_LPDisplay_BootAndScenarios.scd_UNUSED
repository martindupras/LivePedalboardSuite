// Test_LPDisplay_BootAndScenarios.scd
// v0.1.0
// MD 20251003-1232

/* Purpose / Style
- Bring up LPDisplay, attach the adapter, and exercise CommandManager text updates.
- Expect the final expression in block [A] to print '-> a Window'.
- Style: var-first, tilde vars, known-good SC API, AppClock.defer inside classes only.
*/

(
// [A] Bring-up (-> a Window)
var win;

"--- LPDisplay bring-up ---".postln;
thisProcess.openHelpFile ? nil;  // no-op safety
win = { Start_LiveMagicPedalboardSuite_LPDisplay.scd }.postln; // (note: just a breadcrumb in console)
(
// actually evaluate the bring-up inline to avoid external dependency:
var ensureServerReady, closeExistingLPDisplayWindows, openLP;
ensureServerReady = { var s = Server.default; s.waitForBoot({ s.initTree; s.defaultGroup.tryPerform(\freeAll) }); true };
closeExistingLPDisplayWindows = {
    Window.allWindows.select({ arg w;
        var n = w.tryPerform(\name);
        n.notNil and: { n.asString.contains("Layout Test") }
    }).do(_.close);
    nil
};
openLP = { var inst, w; inst = LPDisplayLayoutWindow.new(nil); w = inst.open; ~guiLP = inst; ~lp_window = w; w };
ensureServerReady.(); closeExistingLPDisplayWindows.(); openLP.()  // -> a Window
);

// [B] Adapter in place
"--- Adapter ---".postln;
(
// inline load of the adapter:
var asStringSafe = { arg obj; obj.asString };
~lp_displayAdapter = IdentityDictionary[
    \showExpectation -> { arg text, _idx=0; (~guiLP.notNil).if({ ~guiLP.sendPaneText(\system, asStringSafe.(text)) }); nil },
    \updateTextField -> { arg box, msg;
        var pane = box.asSymbol, t = asStringSafe.(msg), target;
        target = (pane == \state).if({ \system }, { (pane == \choices).if({ \choices }, { \diag }) });
        (~guiLP.notNil).if({ ~guiLP.sendPaneText(target, t) }); nil
    },
    \setOperations -> { arg lines; var joined = ((lines ? []) collect: _.asString).join(Char.nl.asString);
        (~guiLP.notNil).if({ ~guiLP.sendPaneText(\choices, joined) }); nil
    },
    \highlightCurrentColumn -> { arg which; nil },
    \enableMeters -> { arg flag = true; nil }
];
// bind if available:
if(~system.notNil) { var cm = ~system.tryPerform(\commandManager); (cm.notNil).if({ cm.display = ~lp_displayAdapter }) };
"Adapter bound if ~system.commandManager exists.".postln;
);

// [C] Drive a few updates
"--- Smoke text ---".postln;
(
var cm, fakeChoices;
cm = (~system.notNil).if({ ~system.commandManager }, { nil });
~guiLP.sendPaneText(\system, "Mode: idle");    // direct write (LPDisplay API)  [1](https://openuniv-my.sharepoint.com/personal/md24538_open_ac_uk/Documents/Microsoft%20Copilot%20Chat%20Files/allfiles_20251003-1225.txt)
fakeChoices = ["fret 3 → audio", "fret 5 → control", "fret 7 → names"].join(Char.nl.asString);
~guiLP.sendPaneText(\choices, fakeChoices);    // verify choices area
cm.notNil.if({
    cm.display.showExpectation("Mode: test", 0);
    cm.display.updateTextField(\state, "Mode: test");
    cm.display.updateTextField(\choices, fakeChoices);
});
"Check LPDisplay: System & Choices panes should be updated.".postln;
);

// [D] Optional: play with sources shown in LPDisplay’s top panes
~guiLP.setSourceA(\srcA);   // available in your LPDisplay classes  [1](https://openuniv-my.sharepoint.com/personal/md24538_open_ac_uk/Documents/Microsoft%20Copilot%20Chat%20Files/allfiles_20251003-1225.txt)
~guiLP.setSourceB(\srcB);
)