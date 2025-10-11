// MagicDisplayGUI_Fix_MetersNoMovement_v0.3.10.scd
// v0.3.10
// MD timestamp: 2025-09-25

/* Purpose
   - Fix "sound but meters not moving" by:
     * ensuring OUR routing non-destructively
     * reinstalling receiver
     * auto-attaching A(2001)/B(2002) probes to Ndef buses
     * printing quick status
   - Assumes your chains are Ndef(\chainA) and Ndef(\chainB) and are PLAYING.

   Style
   - var-first in every block; no non-local returns (^).
*/

(
var ok, detectBusIndex, aIdx, bIdx, reinstallReceiver, postStatus;

("MagicDisplayGUI_Fix_MetersNoMovement_v0.3.10.scd").postln;
ok = true;

if (~md_ensureRouting.isNil or: { ~md_attachProbesAB.isNil }) {
    "Bring-up not loaded. Run MagicDisplayGUI_New_ServerBootAndProbe_v0.3.7.scd first.".postln;
} {
    // ensure our bus/groups/probe exist without killing your Ndefs
    ~md_ensureRouting.value;

    // reinstall receiver safely
    reinstallReceiver = {
        var existing;
        existing = OSCdef(\md_levels);
        if (existing.notNil) { existing.free; };
        ~md_levelsById = IdentityDictionary.new;
        ~levels = [0.0, 0.0];
        ~md_lastLevelAt = Main.elapsedTime;

        OSCdef(
            \md_levels,
            { |msg, time, addr, recvPort|
                var nodeId, replyId, count, i, outArray;

                nodeId = 0;
                replyId = 0;
                count = 0;
                i = 0;
                outArray = nil;

                if (msg.size >= 3) {
                    nodeId = msg[1].asInteger;
                    replyId = msg[2].asInteger;
                    count = msg.size - 3;
                    outArray = Array.newClear(count);
                    i = 0;
                    while { i < count } {
                        outArray[i] = msg[3 + i].asFloat.clip(0.0, 1.0);
                        i = i + 1;
                    };
                    ~md_levelsById[replyId] = outArray;
                    ~levels = outArray;
                    ~md_lastLevelAt = Main.elapsedTime;
                };
            },
            '/md/levels',
            recvPort: NetAddr.langPort
        );

        true;
    };

    detectBusIndex = { |name|
        var proxy, idx, busObj;
        proxy = Ndef(name);
        idx = -1;
        busObj = nil;
        if (proxy.notNil) {
            busObj = proxy.bus; // valid when proxy has produced output
            if (busObj.notNil) { idx = busObj.index; };
        };
        idx;
    };

    postStatus = {
        var keys, msg;
        keys = ~md_levelsById.keys.asArray.sort;
        msg = "Active replyIDs: " ++ keys.asString;
        msg.postln;
        if (~md_levelsById[2001].notNil) { ("A: " ++ ~md_levelsById[2001].asString).postln; };
        if (~md_levelsById[2002].notNil) { ("B: " ++ ~md_levelsById[2002].asString).postln; };
    };

    reinstallReceiver.value;

    aIdx = detectBusIndex.value(\chainA);
    bIdx = detectBusIndex.value(\chainB);

    ("Detected Ndef buses → A=" ++ aIdx.asString ++ "  B=" ++ bIdx.asString).postln;

    // attach probes directly to those buses (skip -1 safely)
    ~md_attachProbesAB.value(busA: aIdx, busB: bIdx);

    // small delayed status check (allow first /md/levels to arrive)
    AppClock.sched(0.5, {
        postStatus.value;
        nil;
    });
};

ok;
)
