// Hook_PostSwitch_Repair.scd
// v0.1.0
// MD 20251005-1718

/*
Purpose
- TEMPORARY: Patch the CT->MPB adapter *function* (not the class bridge) so that
  right after "/switch" it runs a one-shot repair (≈350 ms after) to:
  1) re-assert CURRENT -> \testmelody,
  2) set NEXT -> \ts0, and
  3) re-materialize chainA/chainB endpoints as 2-ch.
- This confirms the root cause and the permanent MPB fix we will do next.
Style
- var-first; lowercase; AppClock timing only; no server.sync; defensive respondsTo.
*/

(
var wrapOnce, install;

wrapOnce = {
    if(~ct_applyOSCPathToMPB_raw.isNil) {
        ~ct_applyOSCPathToMPB_raw = ~ct_applyOSCPathToMPB; // preserve original
        ~ct_applyOSCPathToMPB     = { |pathString, mpb, gui|  // wrapped
            var p = pathString.asString;
            var res;

            // forward as-is
            res = ~ct_applyOSCPathToMPB_raw.(p, mpb, gui);

            // if it's a switch, schedule a one-shot repair after crossfade settles
            if(p.beginsWith("/switch")) {
                AppClock.sched(0.35, {  // ~350 ms: outside immediate rewrap window
                    var currentSide, currentIsA;

                    currentSide = (~md_currentChain ? \A);
                    currentIsA  = (currentSide == \A);

                    // 1) CURRENT -> testmelody
                    if(mpb.respondsTo(\setSourceCurrent)) { mpb.setSourceCurrent(\testmelody) };
                    if(mpb.respondsTo(\playCurrent))      { mpb.playCurrent };

                    // 2) NEXT -> \ts0 (explicit per-chain, safest)
                    if(currentIsA) {
                        if(mpb.respondsTo(\setSourceB)) { mpb.setSourceB(\ts0) };
                    }{
                        if(mpb.respondsTo(\setSourceA)) { mpb.setSourceA(\ts0) };
                    };

                    // 3) re-materialize endpoints as 2-ch (idempotent, no rewiring)
                    Server.default.bind({
                        if(Ndef(\chainA).notNil) { Ndef(\chainA).ar(2) };
                        if(Ndef(\chainB).notNil) { Ndef(\chainB).ar(2) };
                    });

                    "[HookRepair] post-switch finalize applied (CURRENT=" ++ currentSide.asString ++ ")".postln;
                    nil
                });
            };
            res
        };
        "[HookRepair] adapter function wrapped (temporary).".postln;
    }{
        "[HookRepair] already installed.".postln;
    };
};

install = { wrapOnce.() };
install.();
)