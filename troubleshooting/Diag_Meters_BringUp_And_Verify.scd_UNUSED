// Diag_Meters_BringUp_And_Verify.scd
// v0.1.2
// MD 2025-09-26 14:31 BST

/* Purpose / Style
   Re-install inline taps (A/B + testmelody), then verify /md/levels traffic
   with a short counter. Prints a concise PASS/FAIL line with counts + last values.
   - var-first, descriptive lowercase, AppClock-only, no server.sync.
   - Pass-through taps (return 'in'); generated audio only.
*/

(
var ensureSources, installTapsOnce, installTapsRobust, verifyTraffic, postSummary;
var packetCounts, lastAPair, lastBPair, lastTPair, verifySeconds;

verifySeconds = 0.6;

packetCounts = IdentityDictionary[
    2001 -> 0,   // A
    2002 -> 0,   // B
    1001 -> 0    // testmelody probe
];

lastAPair = [0.0, 0.0];
lastBPair = [0.0, 0.0];
lastTPair = [0.0, 0.0];

ensureSources = {
    Server.default.bind({
        // test melody (generated only)
        if(Ndef(\testmelody).source.isNil) {
            Ndef(\testmelody, {
                var trig, freq, env, pan, scale, indexSel;
                trig = Impulse.kr(2.2);
                scale = [60, 62, 64, 67, 69];
                indexSel = Demand.kr(trig, 0, Dwhite(0, scale.size, inf));
                freq = Select.kr(indexSel, scale).midicps;
                env = Decay2.kr(trig, 0.01, 0.40);
                pan = LFNoise1.kr(0.3).range(-0.7, 0.7);
                Pan2.ar(SinOsc.ar(freq) * env * 0.2, pan)
            });
        };
        Ndef(\testmelody).ar(2);

        // keep sinks alive
        Ndef(\chainA).ar(2);
        Ndef(\chainB).ar(2);

        // silent NEXT
        if(Ndef(\ts0).source.isNil) { Ndef(\ts0, { Silent.ar(2) }) };
        Ndef(\ts0).ar(2);
    });
};

installTapsOnce = { arg rateHz = 18;
    var rateClamped;
    rateClamped = rateHz.asInteger.clip(1, 60);

    Server.default.bind({
        // Chain A
        Ndef(\chainA).filter(\mdTapA, nil);
        Ndef(\chainA).filter(\mdTapA, { arg in;
            var sig, aLeft, aRight;
            sig = in.isArray.if({ in }, { [in, in] });
            aLeft = Amplitude.kr(sig[0]).clip(0, 1);
            aRight = Amplitude.kr(sig[1]).clip(0, 1);
            SendReply.kr(Impulse.kr(rateClamped), "/md/levels", [aLeft, aRight], 2001);
            in
        });

        // Chain B
        Ndef(\chainB).filter(\mdTapB, nil);
        Ndef(\chainB).filter(\mdTapB, { arg in;
            var sig, bLeft, bRight;
            sig = in.isArray.if({ in }, { [in, in] });
            bLeft = Amplitude.kr(sig[0]).clip(0, 1);
            bRight = Amplitude.kr(sig[1]).clip(0, 1);
            SendReply.kr(Impulse.kr(rateClamped), "/md/levels", [bLeft, bRight], 2002);
            in
        });

        // Test probe (always present for diagnostics)
        Ndef(\testmelody).filter(\mdTapT, nil);
        Ndef(\testmelody).filter(\mdTapT, { arg in;
            var sig, tLeft, tRight;
            sig = in.isArray.if({ in }, { [in, in] });
            tLeft = Amplitude.kr(sig[0]).clip(0, 1);
            tRight = Amplitude.kr(sig[1]).clip(0, 1);
            SendReply.kr(Impulse.kr(rateClamped), "/md/levels", [tLeft, tRight], 1001);
            in
        });
    });
};

installTapsRobust = {
    var passIndex, passCount;
    passIndex = 0; passCount = 3;
    AppClock.sched(0.0, {
        installTapsOnce.(18);
        passIndex = passIndex + 1;
        if(passIndex < passCount) { 0.20 } { nil }  // re-run every 200ms, 3 passes
    });
    "[Diag] Inline taps installed (A=2001, B=2002, T=1001) with 3-pass rearm.".postln;
};

verifyTraffic = {
    var defKey;
    defKey = \md_levels_diag_count;

    if(OSCdef.all.at(defKey).notNil) { OSCdef.all.at(defKey).free };

    OSCdef(defKey, { arg msg;
        var replyId, leftVal, rightVal, currentCount;
        if(msg.size < 5) { ^nil };
        replyId = msg[2];
        leftVal  = msg[3].asFloat;
        rightVal = msg[4].asFloat;

        if(replyId == 2001) {
            currentCount = packetCounts[2001] ? 0;
            packetCounts.put(2001, currentCount + 1);
            lastAPair = [leftVal, rightVal];
        };
        if(replyId == 2002) {
            currentCount = packetCounts[2002] ? 0;
            packetCounts.put(2002, currentCount + 1);
            lastBPair = [leftVal, rightVal];
        };
        if(replyId == 1001) {
            currentCount = packetCounts[1001] ? 0;
            packetCounts.put(1001, currentCount + 1);
            lastTPair = [leftVal, rightVal];
        };

        nil
    }, "/md/levels", recvPort: NetAddr.langPort);

    AppClock.sched(verifySeconds, {
        var defObj;
        defObj = OSCdef.all.at(defKey);
        if(defObj.notNil) { defObj.free };
        postSummary.();
        nil
    });

    ("[Diag] Counting /md/levels for " ++ verifySeconds.asString ++ " s…").postln;
};

postSummary = {
    var aCount, bCount, tCount, message;
    aCount = packetCounts[2001] ? 0;
    bCount = packetCounts[2002] ? 0;
    tCount = packetCounts[1001] ? 0;

    message = "RESULT /md/levels  A=" ++ aCount.asString
        ++ "  B=" ++ bCount.asString
        ++ "  T=" ++ tCount.asString
        ++ "  lastA=" ++ lastAPair.asString
        ++ "  lastB=" ++ lastBPair.asString
        ++ "  lastT=" ++ lastTPair.asString;

    message.postln;
};

// run
ensureSources.();
installTapsRobust.();
verifyTraffic.();
)
