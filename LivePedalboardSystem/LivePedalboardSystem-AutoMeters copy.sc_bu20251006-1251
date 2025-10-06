// LivePedalboardSystem-AutoMeters.sc
// v0.2.1
// MD 20251003-1539

/*
Purpose
- Put SendPeakRMS taps directly inside Ndef(\chainA) and Ndef(\chainB) so LPDisplay meters
  update via OSC paths /peakrmsA and /peakrmsB with replyIDs A=1, B=2.
- No separate "retap" scripts; taps reinstall automatically after "/switch".
Style
- Class extension only; var-first; lowercase methods; Server.default.bind for server ops;
  AppClock for GUI; no server.sync; no non-local returns.
*/

+ LivePedalboardSystem {

    enableAutoMeters { arg rate = 18, postSwitchDelay = 0.35;
        var installTaps, rearmGui, wrapAdapter;

        installTaps = {
            Server.default.bind({
                [\chainA, \chainB].do({ arg key, index;
                    var addr, replyId, r;
                    // 1) Clear any prior tap keys (compat with older builds)
                    if(Ndef(key).notNil) {
                        Ndef(key).clear(\ampTap);
                        Ndef(key).clear(\meterTap);
                    };
                    // 2) Configure address + reply id per chain
                    addr = (index == 0).if({ '/peakrmsA' }, { '/peakrmsB' });
                    replyId = (index == 0).if({ 1 }, { 2 });
                    r = rate.clip(1, 60);

                    // 3) Inline peak/RMS UGen tap (pass-through)
                    Ndef(key).filter(\meterTap, { arg in;
                        var sig;
                        sig = in.isArray.if({ in }, { [in, in] }); // mono-safe: duplicate to stereo
                        // LPDisplay expects SendPeakRMS with the usual /peakrmsA/B paths
                        SendPeakRMS.kr(sig, r, 3, addr, replyId);
                        in
                    });
                });
            });
        };

        rearmGui = {
            AppClock.sched(0.05, {
                var g, p;
                g = this.statusDisplay;
                p = this.pedalboard;
                if(g.notNil and: { g.respondsTo(\enableMeters) }) {
                    g.enableMeters(false);
                    g.enableMeters(true);
                };
                if(p.notNil and: { p.respondsTo(\printChains) }) { p.printChains };
                nil
            });
        };

        wrapAdapter = {
            // Only if the CommandTree -> MPB adapter is present
            if(~ct_applyOSCPathToMPB.isNil) {
                "⚠️ [AutoMeters] adapter not loaded; run installAdapterBridge first".warn;
            }{
                // Preserve raw adapter once
                if(~ct_applyOSCPathToMPB_raw.isNil) { ~ct_applyOSCPathToMPB_raw = ~ct_applyOSCPathToMPB };
                // Wrap once so taps are reinstalled after "/switch"
                if(~ct_applyOSCPathToMPB_withMeters.isNil) {
                    ~ct_applyOSCPathToMPB_withMeters = { arg pathString, mpb, gui;
                        var p, res;
                        p = pathString.asString;
                        res = ~ct_applyOSCPathToMPB_raw.(p, mpb, gui);
                        if(p == "/switch") {
                            AppClock.sched(postSwitchDelay, { installTaps.(); rearmGui.(); nil });
                        };
                        res
                    };
                    ~ct_applyOSCPathToMPB = ~ct_applyOSCPathToMPB_withMeters;
                    "[AutoMeters] post-switch reinstaller active".postln;
                };
            };
        };

        // One-shot now, and set up the post-switch hook
        installTaps.();
        rearmGui.();
        wrapAdapter.();
        "[AutoMeters] PeakRMS taps installed (rate=%), GUI re-armed".format(rate).postln;
        ^this
    }
}