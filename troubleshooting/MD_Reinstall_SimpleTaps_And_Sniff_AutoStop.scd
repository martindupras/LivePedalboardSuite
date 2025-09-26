// MD_Reinstall_SimpleTaps_And_Sniff_AutoStop.scd
// v0.1.0
// MD 2025-09-26 17:55 BST

/* Purpose / Style
   Purpose: Replace current /md/levels taps with a *simple* version that sends raw Amplitude.kr values
            (no LinExp, no LagUD) for A/B sinks. Then install a finite sniffer that prints exactly
            6 lines (one per second) and auto-stops.
   Style:   var-first; descriptive lowercase variable names; Server.default.bind; no server.sync; AppClock.
*/

(
// ---- reinstall simple taps (server-side), replyIDs: A=2001, B=2002
var reinstallSimpleTaps;

reinstallSimpleTaps = {
    Server.default.bind({
        var rateHertz, attackSec, releaseSec, floorAmp;

        rateHertz  = 24;
        attackSec  = 0.01;
        releaseSec = 0.20;
        floorAmp   = 1e-5;

        // CHAIN A
        Ndef(\chainA).filter(\mdSimpleTapA, { arg inSig;
            var inputPair, ampLeft, ampRight;

            inputPair = inSig.isArray.if({ inSig }, { [inSig, inSig] });
            ampLeft   = Amplitude.kr(inputPair[0], attackSec, releaseSec).clip(floorAmp, 1.0);
            ampRight  = Amplitude.kr(inputPair[1], attackSec, releaseSec).clip(floorAmp, 1.0);

            // Send raw amplitudes (0..1)
            SendReply.kr(Impulse.kr(rateHertz), "/md/levels", [ampLeft, ampRight], 2001);
            inSig
        });

        // CHAIN B
        Ndef(\chainB).filter(\mdSimpleTapB, { arg inSig;
            var inputPair, ampLeft, ampRight;

            inputPair = inSig.isArray.if({ inSig }, { [inSig, inSig] });
            ampLeft   = Amplitude.kr(inputPair[0], attackSec, releaseSec).clip(floorAmp, 1.0);
            ampRight  = Amplitude.kr(inputPair[1], attackSec, releaseSec).clip(floorAmp, 1.0);

            SendReply.kr(Impulse.kr(rateHertz), "/md/levels", [ampLeft, ampRight], 2002);
            inSig
        });
    });
    "MDSIMPLE: raw amplitude taps installed (/md/levels; A=2001 B=2002).".postln;
};

reinstallSimpleTaps.();
nil
);

// ---- finite sniffer: prints exactly 6 lines and auto-stops
(
var valuesById, oscKey, remainingLines, reporterRoutine;

// Shared store
valuesById = ~md_levelsById ? IdentityDictionary.new;
~md_levelsById = valuesById;

// Finite cycles to print
remainingLines = 6;

// Clean previous finite sniffer (if any)
oscKey = \md_levels_sniffer_fixed;
if(OSCdef.all.at(oscKey).notNil) { OSCdef.all.at(oscKey).free };

// Listener: only update the dict; no console spam here
OSCdef(oscKey, { arg oscMessage;
    var replyId, leftVal, rightVal;

    if(oscMessage.size >= 5) {
        replyId = oscMessage[2];
        leftVal  = oscMessage[3];
        rightVal = oscMessage[4];

        // Guards + clip 0..1
        leftVal  = (leftVal.isNumber  and: { leftVal.isNaN.not })  .if({ leftVal.clip(0,1) }, { 0.0 });
        rightVal = (rightVal.isNumber and: { rightVal.isNaN.not }) .if({ rightVal.clip(0,1) }, { 0.0 });

        valuesById.put(replyId, [leftVal, rightVal]);
    };
    nil
}, "/md/levels", recvPort: NetAddr.langPort);

// Reporter: 1 Hz; prints 6 lines then stops and frees listener
reporterRoutine = Routine({
    var keepRunning;
    keepRunning = true;

    while({ keepRunning and: { remainingLines > 0 } }, {
        var pairA, pairB, textA, textB;

        pairA = valuesById.at(2001) ? [0, 0];
        pairB = valuesById.at(2002) ? [0, 0];

        textA = "A(L,R)=(" ++ pairA[0].round(0.01) ++ "," ++ pairA[1].round(0.01) ++ ")";
        textB = "B(L,R)=(" ++ pairB[0].round(0.01) ++ "," ++ pairB[1].round(0.01) ++ ")";

        ("MDSIMPLE: " ++ textA ++ "  " ++ textB).postln;

        remainingLines = remainingLines - 1;
        1.0.wait;
    });

    // Auto-clean: free listener and stop routine
    var oscObj;
    oscObj = OSCdef.all.at(oscKey);
    if(oscObj.notNil) { oscObj.free; "MDSIMPLE: listener freed.".postln };

    "MDSIMPLE: reporter finished.".postln;
}).play(AppClock);

nil
)
