// LivePedalboardSystem-AutoMeters.sc
// v0.2.0
// MD 20250924-1905

/*
Purpose
- Make meters "just work":
  1) Install inline amplitude taps on sink proxies Ndef(\chainA) and Ndef(\chainB).
     These taps send /ampA and /ampB directly from the actual sink audio.
  2) Auto-reinstall taps after every "/switch" (post crossfade & audit).
  3) Re-arm GUI meter responders and repaint chains.

Style
- Class extension only; var-first; lowercase; no server.sync.
- Server ops in Server.default.bind; GUI ops via AppClock.sched.
*/

+ LivePedalboardSystem {

    enableAutoMeters { arg rate = 18, postSwitchDelay = 0.35;
        var installTaps, rearmGui, wrapAdapter;

        installTaps = {
            Server.default.bind({
                [\chainA, \chainB].do({ arg key, index;
                    var addr;
                    addr = (index == 0).if({ '/ampA' }, { '/ampB' });
                    Ndef(key).filter(\ampTap, { arg in;
                        var sig, aL, aR, r;
                        sig = in.isArray.if({ in }, { [in, in] }); // mono-safe
                        r   = rate.clip(1, 60);
                        aL  = Amplitude.kr(sig[0]).clip(0, 1);
                        aR  = Amplitude.kr(sig[1]).clip(0, 1);
                        SendReply.kr(Impulse.kr(r), addr, [aL, aR]);
                        in // pass-through
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
                if(p.notNil and: { p.respondsTo(\printChains) }) {
                    p.printChains; // repaint CURRENT/NEXT panels
                };
                nil
            });
        };

        wrapAdapter = {
            // Only if adapter is present in the session (~ct_applyOSCPathToMPB)
            if(~ct_applyOSCPathToMPB.isNil) {
                "⚠️ [AutoMeters] adapter not loaded; run installAdapterBridge first".warn;
            }{
                // Preserve the raw adapter once
                if(~ct_applyOSCPathToMPB_raw.isNil) {
                    ~ct_applyOSCPathToMPB_raw = ~ct_applyOSCPathToMPB;
                };
                // Wrap once to reinstall taps after "/switch"
                if(~ct_applyOSCPathToMPB_withMeters.isNil) {
                    ~ct_applyOSCPathToMPB_withMeters = { arg pathString, mpb, gui;
                        var p, res;
                        p = pathString.asString;
                        res = ~ct_applyOSCPathToMPB_raw.(p, mpb, gui);
                        if(p == "/switch") {
                            AppClock.sched(postSwitchDelay, {
                                installTaps.();
                                rearmGui.();
                                nil
                            });
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

        "[AutoMeters] Inline taps installed (rate=%), GUI re-armed".format(rate).postln;
        ^this
    }
}
