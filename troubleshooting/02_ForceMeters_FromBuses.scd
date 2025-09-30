// 02_ForceMeters_FromBuses.scd
// v0.1.1
// MD 20250928-1935

(
// Purpose
// - Bypass older meter paths. Tap Ndef buses directly and send on "/md/levels_bus".
// - Correct parsing: SendReply => msg[0]=path, msg[1]=nodeID, msg[2]=replyID, msg[3]=L, msg[4]=R.
// Style
// - var-first; no server.sync; server ops in Server.default.bind.

var makeTapDefOnce, installBusTaps, installHudReceiver, aBus, bBus, tBus;

makeTapDefOnce = {
    SynthDef(\md_busTap2, { |inBus=0, rate=24, replyID=2001|
        var sig, aL, aR;
        sig = In.ar(inBus, 2);
        aL  = Amplitude.kr(sig[0], 0.01, 0.20).clip(0, 1);
        aR  = Amplitude.kr(sig[1], 0.01, 0.20).clip(0, 1);
        SendReply.kr(Impulse.kr(rate), "/md/levels_bus", [aL, aR], replyID);
    }).add;
    "🔧 SynthDef \\md_busTap2 installed.".postln;
};

installBusTaps = {
    Server.default.bind({
        aBus = Ndef(\chainA).bus.index;
        bBus = Ndef(\chainB).bus.index;
        tBus = Ndef(\testmelody).bus.index;
        if(~md_busTapA.notNil) { ~md_busTapA.free; ~md_busTapA = nil };
        if(~md_busTapB.notNil) { ~md_busTapB.free; ~md_busTapB = nil };
        if(~md_busTapT.notNil) { ~md_busTapT.free; ~md_busTapT = nil };
        ~md_busTapA = Synth.tail(s.defaultGroup, \md_busTap2, [\inBus, aBus, \rate, 24, \replyID, 2001]);
        ~md_busTapB = Synth.tail(s.defaultGroup, \md_busTap2, [\inBus, bBus, \rate, 24, \replyID, 2002]);
        ~md_busTapT = Synth.tail(s.defaultGroup, \md_busTap2, [\inBus, tBus, \rate, 24, \replyID, 1001]);
        "📡 Bus taps active (A=2001 / B=2002 / Test=1001).".postln;
    });
};

installHudReceiver = {
    var key;
    key = \md_levels_hud;
    if(OSCdef.all.at(key).notNil) { OSCdef(key).free };

    ~md_levelsById   = ~md_levelsById ? IdentityDictionary.new;
    ~md_lastMsgStamp = SystemClock.seconds.asFloat;

    OSCdef(key, { |msg|
        var id, l, r;
        if(msg.size < 5) { nil } {
            id = msg[2].asInteger;         // 2001 / 2002 / 1001
            l  = msg[3].asFloat.clip(0,1); // left
            r  = msg[4].asFloat.clip(0,1); // right
            ~md_levelsById.put(id, [l, r]);
            ~md_lastMsgStamp = SystemClock.seconds.asFloat;
        };
        nil
    }, "/md/levels_bus", recvPort: NetAddr.langPort);

    "[HUD] listening /md/levels_bus (key=md_levels_hud; ids 2001/2002/1001)".postln;
};

makeTapDefOnce.value;
installBusTaps.value;
installHudReceiver.value;
"✅ Forced bus meters installed; HUD bridged to dict.".postln;
)
