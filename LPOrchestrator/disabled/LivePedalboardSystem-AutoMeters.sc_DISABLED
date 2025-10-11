// LivePedalboardSystem-AutoMeters.sc
// v0.2.2
// MD 20251006-1310

/* Purpose
- Align SendPeakRMS reply IDs with spec: A=2001, B=2002; /peakrmsA and /peakrmsB unchanged.
*/

+ LivePedalboardSystem {
    enableAutoMeters { arg rate = 18, postSwitchDelay = 0.35;
        var installTaps, rearmGui, wrapAdapter;
        installTaps = {
            Server.default.bind({
                [\chainA, \chainB].do({ arg key, index;
                    var addr, replyId, r;
                    Ndef(key).clear(\ampTap);  Ndef(key).clear(\meterTap);
                    addr = (index == 0).if({ '/peakrmsA' }, { '/peakrmsB' });
                    replyId = (index == 0).if({ 2001 }, { 2002 }); // ← change here
                    r = rate.clip(1, 60);
                    Ndef(key).filter(\meterTap, { arg in;
                        var sig;
                        sig = in.isArray.if({ in }, { [in, in] });
                        SendPeakRMS.kr(sig, r, 3, addr, replyId);
                        in
                    });
                });
            });
        };
        /* ... unchanged rearmGui & wrapAdapter ... */
        installTaps.(); rearmGui.(); wrapAdapter.();
        " [AutoMeters] PeakRMS taps installed (rate=%), GUI re-armed".format(rate).postln;
        ^this
    }
}