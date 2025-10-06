// LPDisplay_BindAdapter_Inline.scd
// v0.1.0
// MD 20251003-1302

(
var cm;
~lp_adapter = LPDisplayAdapter.new(~guiLP);  // ~guiLP is your LPDisplayLayoutWindow controller
cm = (~system.notNil).if({ ~system.tryPerform(\commandManager) }, { nil });
(cm.notNil).if({ cm.display = ~lp_adapter; "Adapter bound.".postln; });

// quick sanity
(~guiLP.notNil).if({
    ~guiLP.sendPaneText(\system, "Adapter OK");
    ~guiLP.sendPaneText(\choices, "fret 3 → audio\nfret 5 → control\nfret 7 → names");
});
)
