// 00_Reset_KnownClean_State.scd
// v1.0.1
// MD 20250929-0918

(
// Purpose
// - Close MagicDisplay windows; free HUD OSCdefs/bridges/probes.
// - Stop Ndefs; clear server tree; clear HUD dictionaries.
// Style
// - var-first; no server.sync; server ops in Server.default.bind; UI via AppClock.

var closeMagicDisplayWindows, freeHudReceivers, stopNdefs, clearGlobals;

closeMagicDisplayWindows = {
    var wins, i, w, nm;
    wins = Window.allWindows; i = 0;
    while { i < wins.size } {
        w = wins[i];
        nm = w.tryPerform(\name);
        if(nm.notNil and: { nm.asString.beginsWith("MagicDisplayGUI") }) { w.close };
        i = i + 1;
    };
};

freeHudReceivers = {
    [ \md_levels_hud, \md_levels_gui_bridge, \probe_levels, \probe_levels_gui, \probe_levels_bus ].do { |k|
        var d = OSCdef.all.at(k);
        if(d.notNil) { d.free };
    };
};

stopNdefs = {
    Server.default.bind({
        [ \chainA, \chainB, \testmelody, \ts0 ].do { |k|
            if(Ndef(k).isPlaying) { Ndef(k).stop };
        };
        s.defaultGroup.freeAll;
    });
};

clearGlobals = {
    ~md_levelsById   = IdentityDictionary.new;
    ~md_lastMsgStamp = SystemClock.seconds.asFloat;
    ~md_busTapA = nil; ~md_busTapB = nil;
    ~system = nil; ~mpb = nil; ~gui = nil;
};

closeMagicDisplayWindows.value;
freeHudReceivers.value;
stopNdefs.value;
clearGlobals.value;

"✅ Reset: GUI closed, OSCdefs freed, Ndefs stopped, globals cleared.".postln;
)
