// Hook_Switch_NoXfade_FIX.scd
// v0.1.1
// MD 20251005-1758

/*
Purpose
- TEMP: bypass MagicPedalboard's internal crossfade for "/switch".
- IMPORTANT CHANGE vs v0.1.0: Do *all* mapping *after* the bridge toggles
  ~md_currentChain, so CURRENT is the new active side when we assign sources.
Behavior on "/switch":
  1) Do NOT call the original adapter (prevents MPB crossfade).
  2) After ~60 ms (enough for the bridge to toggle the current side & update UI):
     - set CURRENT -> \testmelody
     - set NEXT    -> \ts0
     - mpb.playCurrent
     - rematerialize endpoints as 2-ch
- All other paths pass through unchanged.
Style
- var-first; lowercase; no server.sync; AppClock for timing; defensive respondsTo.
*/

(
var install, wrap;

install = {
    var prev;

    // Keep the currently-active adapter (it may already be a wrapper from AutoMeters)
    prev = ~ct_applyOSCPathToMPB;

    // Install wrapper only once (idempotent-ish)
    if(~ct_applyOSCPathToMPB_prev.isNil) {
        ~ct_applyOSCPathToMPB_prev = prev;
    } {
        // If already installed, refresh wrapper to the latest prev
        prev = ~ct_applyOSCPathToMPB_prev;
    };

    ~ct_applyOSCPathToMPB = { |pathString, mpb, gui|
        var p, isSwitch;

        p = pathString.asString;
        isSwitch = p.beginsWith("/switch");

        if(isSwitch.not) {
            ^~ct_applyOSCPathToMPB_prev.(p, mpb, gui);
        };

        // --- switch path (NO XFADE) ---
        // We *don’t* forward /switch to the prev adapter.
        // Instead, we wait a tick so the bridge can toggle ~md_currentChain.
        AppClock.sched(0.06, {
            var currentSide, currentIsA;

            currentSide = (~md_currentChain ? \A); // now reflects the new ACTIVE side
            currentIsA  = (currentSide == \A);

            if(currentIsA) {
                if(mpb.respondsTo(\setSourceA)) { mpb.setSourceA(\testmelody) };
                if(mpb.respondsTo(\setSourceB)) { mpb.setSourceB(\ts0) };
            }{
                if(mpb.respondsTo(\setSourceA)) { mpb.setSourceA(\ts0) };
                if(mpb.respondsTo(\setSourceB)) { mpb.setSourceB(\testmelody) };
            };

            if(mpb.respondsTo(\playCurrent)) { mpb.playCurrent };

            Server.default.bind({
                if(Ndef(\chainA).notNil) { Ndef(\chainA).ar(2) };
                if(Ndef(\chainB).notNil) { Ndef(\chainB).ar(2) };
            });

            ("[NoXfade] switch mapped AFTER toggle: CURRENT=" ++ currentSide.asString
             ++ " (CURRENT->\\testmelody, NEXT->\\ts0)").postln;
            nil
        });

        ^nil
    };

    "[NoXfade] Hook installed (mapping AFTER bridge toggle).".postln;
};

install.();
)