// Fix_Meters_KnownGood.scd
// v0.1.0
// MD 2025-09-26 14:45 BST

/* Purpose / Style
   Minimal, known‑good meter bring‑up:
   1) Install a /md/levels receiver (-> ~md_levelsById, ~md_lastMsgStamp).
   2) Re-arm inline taps on chainA (2001), chainB (2002), testmelody (1001) via Ndef.filter.
   3) Heartbeat prints "last /md/levels: X s" every ~2s so we know it's alive.
   - var-first; descriptive lowercase names; AppClock-only; no server.sync; no '?:'.
   - Pass-through taps (return 'in'); *generated audio only*.
*/

(
var installReceiver, ensureSources, installTaps, startHeartbeat;
var rateHz, receiverKey, heartbeatRoutine;

rateHz = 18;
receiverKey = \md_levels_hud;

// ---------- 1) /md/levels receiver ----------
installReceiver = {
    var existing;
    ~md_levelsById   = ~md_levelsById   ? IdentityDictionary.new;
    ~md_lastMsgStamp = ~md_lastMsgStamp ? SystemClock.seconds.asFloat;

    existing = OSCdef.all.at(receiverKey);
    if(existing.notNil) { existing.free };

    OSCdef(receiverKey, { arg msg;
        var replyId, leftVal, rightVal;
        if(msg.size < 5) { ^nil };
        replyId  = msg[2];
        leftVal  = msg[3].asFloat.clip(0, 1);
        rightVal = msg[4].asFloat.clip(0, 1);
        ~md_levelsById.put(replyId, [leftVal, rightVal]);
        ~md_lastMsgStamp = SystemClock.seconds.asFloat;
        nil
    }, "/md/levels", recvPort: NetAddr.langPort);

    ("[HUD] /md/levels listener installed (key=" ++ receiverKey.asString ++ ")").postln;
};

// ---------- 2) Sources / sinks kept alive (no server.sync) ----------
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

        // silent NEXT
        if(Ndef(\ts0).source.isNil) { Ndef(\ts0, { Silent.ar(2) }) };
        Ndef(\ts0).ar(2);

        // keep sinks "awake" at audio rate (no audible change)
        Ndef(\chainA).ar(2);
        Ndef(\chainB).ar(2);
    });
    "[Meters] sources/sinks ensured.".postln;
};

// ---------- 3) Inline taps via known-good Ndef.filter ----------
installTaps = {
    var rateClamped;
    rateClamped = rateHz.asInteger.clip(1, 60);

    Server.default.bind({
        // Chain A (replyID 2001)
        Ndef(\chainA).filter(\mdTapA, { arg in;
            var sig, aLeft, aRight;
            sig = in.isArray.if({ in }, { [in, in] });
            aLeft = Amplitude.kr(sig[0]).clip(0, 1);
            aRight = Amplitude.kr(sig[1]).clip(0, 1);
            SendReply.kr(Impulse.kr(rateClamped), "/md/levels", [aLeft, aRight], 2001);
            in
        });

        // Chain B (replyID 2002)
        Ndef(\chainB).filter(\mdTapB, { arg in;
            var sig, bLeft, bRight;
            sig = in.isArray.if({ in }, { [in, in] });
            bLeft = Amplitude.kr(sig[0]).clip(0, 1);
            bRight = Amplitude.kr(sig[1]).clip(0, 1);
            SendReply.kr(Impulse.kr(rateClamped), "/md/levels", [bLeft, bRight], 2002);
            in
        });

        // Test probe (replyID 1001)
        Ndef(\testmelody).filter(\mdTapT, { arg in;
            var sig, tLeft, tRight;
            sig = in.isArray.if({ in }, { [in, in] });
            tLeft = Amplitude.kr(sig[0]).clip(0, 1);
            tRight = Amplitude.kr(sig[1]).clip(0, 1);
            SendReply.kr(Impulse.kr(rateClamped), "/md/levels", [tLeft, tRight], 1001);
            in
        });
    });
    "[Meters] inline taps armed (A=2001, B=2002, T=1001).".postln;
};

// ---------- 4) Heartbeat (light) ----------
startHeartbeat = {
    var beatInterval, routine;
    beatInterval = 2.0;
    routine = Routine({
        var keepRunning, now, lastAge;
        keepRunning = true;
        while({ keepRunning }, {
            now = SystemClock.seconds.asFloat;
            lastAge = (now - (~md_lastMsgStamp ? now)).round(0.01);
            ("[Meters] last /md/levels: " ++ lastAge.asString ++ " s").postln;
            beatInterval.wait;
        });
    }).play(AppClock);
    routine
};

// Run steps
installReceiver.();
ensureSources.();
installTaps.();

// (Optional) start/refresh overlay drawing here if you added one earlier.

// Heartbeat so we know packets are arriving
heartbeatRoutine = startHeartbeat.();
)
