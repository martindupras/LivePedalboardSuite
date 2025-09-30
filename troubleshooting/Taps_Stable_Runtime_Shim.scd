// Taps_Stable_Runtime_Shim.scd
// v0.1.1 (fix SendReply replyID position)
// MD timestamp: 2025-09-27 19:35 GMT+1

/*
Purpose
- Publish /md/levels with replyID in proper slot (msg[2]) so listeners match A=2001 / B=2002.

Style / Guard Rails
- Single () block; VAR-FIRST; no non-local returns; no server.sync.
*/

(
var server, rateHz, attachTap, ensureProxy, banner;

server = Server.default;
rateHz = 12;

banner = { arg text; ("[TAPS] " ++ text).postln; };

ensureProxy = { arg name, numCh;
    (Ndef(name).rate != \audio).if({
        Ndef(name).clear;
        Ndef(name).ar(numCh ? 2);
    });
};

attachTap = { arg name, key, replyID;
    Ndef(name).filter(key, { arg inSig;
        var sig, chans, l, r, ampL, ampR, trig;
        sig = inSig;
        chans = sig.asArray;
        l = (chans.size >= 1).if({ chans[0] }, { Silent.ar });
        r = (chans.size >= 2).if({ chans[1] }, { l }); // mono -> duplicate
        ampL = Lag.kr(Amplitude.kr(l, 0.01, 0.2), 0.08);
        ampR = Lag.kr(Amplitude.kr(r, 0.01, 0.2), 0.08);
        trig = Impulse.kr(rateHz);

        // *** Correct: replyID is the 4th arg, values exclude replyID
        SendReply.kr(trig, '/md/levels', [ampL, ampR], replyID);

        sig
    });
};

Server.default.bind({
    ensureProxy.(\chainA, 2);
    ensureProxy.(\chainB, 2);
    attachTap.(\chainA, \eodTapA, 2001);
    attachTap.(\chainB, \eodTapB, 2002);
});

banner.("Taps active (/md/levels) — A=2001, B=2002 at " ++ rateHz ++ " Hz.");
"-> Taps_Stable_Runtime_Shim ready".postln;
Window.allWindows.detect({ |w| w.name.asString.beginsWith("MagicDisplayGUI") }) ? nil;
)
