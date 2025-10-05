// Hook_Switch_NoXfade_FIX2.scd
// v0.1.2
// MD 20251005-1812

/*
Purpose
- TEMP: Bypass MPB's crossfade AND toggle CURRENT/NEXT ourselves.
- On "/switch":
  1) toggle ~md_currentChain (A<->B),
  2) update LPDisplay ACTIVE/NEXT via CommandManager.display,
  3) map sources: CURRENT->\testmelody, NEXT->\ts0,
  4) playCurrent (after a tiny tick),
  5) keep endpoints stereo with ar(2).

All other adapter paths pass through unchanged.
Style
- var-first; lowercase; no server.sync; AppClock timing only; defensive respondsTo.
*/

(
var install;

install = {
    var prev;
	        var oldSide, newSide, cm, disp, currentIsA;

    // keep the latest adapter in prev (may be wrapped by AutoMeters)
    if(~ct_applyOSCPathToMPB_prev.isNil) {
        ~ct_applyOSCPathToMPB_prev = ~ct_applyOSCPathToMPB;
    };
    prev = ~ct_applyOSCPathToMPB_prev;

    ~ct_applyOSCPathToMPB = { |pathString, mpb, gui|
        var p, isSwitch;

        p = pathString.asString;
        isSwitch = p.beginsWith("/switch");

        if(isSwitch.not) {
            ^prev.(p, mpb, gui);
        };

        // --- OUR SIMPLE SWITCH (no MPB crossfade, self-toggle) ---
/*        var oldSide, newSide, cm, disp, currentIsA;*/

        oldSide = (~md_currentChain ? \A);
        newSide = (oldSide == \A).if({ \B }, { \A });
        ~md_currentChain = newSide;  // <-- self-toggle

        // update LPDisplay ACTIVE/NEXT
        cm = ~system.tryPerform(\commandManager);
        disp = cm.tryPerform(\display);
        if(disp.notNil) { disp.tryPerform(\setActiveChainVisual, newSide) };

        currentIsA = (newSide == \A);

        // map sources explicitly (CURRENT->\testmelody, NEXT->\ts0)
        if(currentIsA) {
            if(mpb.respondsTo(\setSourceA)) { mpb.setSourceA(\testmelody) };
            if(mpb.respondsTo(\setSourceB)) { mpb.setSourceB(\ts0) };
        }{
            if(mpb.respondsTo(\setSourceA)) { mpb.setSourceA(\ts0) };
            if(mpb.respondsTo(\setSourceB)) { mpb.setSourceB(\testmelody) };
        };

        // keep endpoints stereo & play current
        Server.default.bind({
            if(Ndef(\chainA).notNil) { Ndef(\chainA).ar(2) };
            if(Ndef(\chainB).notNil) { Ndef(\chainB).ar(2) };
        });

        AppClock.sched(0.03, {  // tiny tick
            if(mpb.respondsTo(\playCurrent)) { mpb.playCurrent };
            nil
        });

        ("[NoXfade2] toggled " ++ oldSide.asString ++ "→" ++ newSide.asString
          ++ "  (CURRENT->\\testmelody, NEXT->\\ts0)").postln;

        ^nil  // IMPORTANT: do not call prev for "/switch"
    };

    "[NoXfade2] Hook installed: self-toggle + simple mapping after switch.".postln;
};

install.();
)