// Disable_CTFX_Crossfade_Adapter.scd
// v0.2.1
// MD 20251005-1919

/*
Purpose
- TEMP: Disable CommandTree->MPB crossfade for "/switch".
- Implement a simple, immediate switch (CURRENT->\testmelody, NEXT->\ts0, playCurrent).
- All other adapter paths pass through unchanged.

Style
- var-first; lowercase; no server.sync; AppClock-tick for playCurrent; defensive checks.
*/

(
var install, ensureStereo, setSources, updateVisual, simpleSwitch, prev;

// helper: keep endpoints 2-ch
ensureStereo = {
    Server.default.bind({
        if(Ndef(\chainA).notNil) { Ndef(\chainA).ar(2) };
        if(Ndef(\chainB).notNil) { Ndef(\chainB).ar(2) };
    });
};

// helper: set per-chain sources for a given CURRENT symbol
setSources = { |mpb, currentSym = \A|
    var currentIsA;
    currentIsA = (currentSym == \A);
    if(mpb.notNil) {
        if(currentIsA) {
            if(mpb.respondsTo(\setSourceA)) { mpb.setSourceA(\testmelody) };
            if(mpb.respondsTo(\setSourceB)) { mpb.setSourceB(\ts0) };
        }{
            if(mpb.respondsTo(\setSourceA)) { mpb.setSourceA(\ts0) };
            if(mpb.respondsTo(\setSourceB)) { mpb.setSourceB(\testmelody) };
        };
    };
};

// helper: update LPDisplay
updateVisual = { |currentSym = \A|
    var cm, disp;
    cm   = ~system.tryPerform(\commandManager);
    disp = cm.tryPerform(\display);
    if(disp.notNil) { disp.tryPerform(\setActiveChainVisual, currentSym) };
};

// the simple switch
simpleSwitch = { |mpb|
    var oldSide, newSide;

    oldSide = (~md_currentChain ? \A);
    newSide = (oldSide == \A).if({ \B }, { \A });
    ~md_currentChain = newSide;

    updateVisual.(newSide);
    setSources.(mpb, newSide);
    ensureStereo.();

    AppClock.sched(0.03, { if(mpb.respondsTo(\playCurrent)) { mpb.playCurrent }; nil });

    ("[NoXfadeAdapter] toggled " ++ oldSide.asString ++ "→" ++ newSide.asString
     ++ " (CURRENT->\\testmelody, NEXT->\\ts0)").postln;
    nil
};

install = {
    // keep original adapter once (safe to re-run)
    if(~ct_applyOSCPathToMPB_prev.isNil) {
        ~ct_applyOSCPathToMPB_prev = ~ct_applyOSCPathToMPB;
    };
    prev = ~ct_applyOSCPathToMPB_prev;

    // override adapter
    ~ct_applyOSCPathToMPB = { |pathString, mpbArg, gui|
        var p, isSwitch, mpbLocal;
        p        = pathString.asString;
        isSwitch = p.beginsWith("/switch");
        mpbLocal = mpbArg ? ~system.tryPerform(\pedalboard);

        if(isSwitch) {
            // IMPORTANT: do NOT call prev for "/switch"
            ^simpleSwitch.(mpbLocal);
        }{
            ^prev.(p, mpbArg, gui)
        };
    };

    ~ct_applyOSCPathToMPB_tag = "NoXfadeAdapter_v0.2.1";
    "[NoXfadeAdapter] installed: /switch will NOT call the original crossfade.".postln;
};

// run now
install.();
)
