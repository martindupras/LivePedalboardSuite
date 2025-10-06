// MagicDisplayGUI_New_ServerBootAndProbe_v0.3.8.scd
// v0.3.8
// MD 2025-09-25 15:22 BST

/*
Purpose
- Non-destructive bring-up of OSC receiver and A/B meters:
  A) Preferred: inline in-proxy taps on Ndef(\chainA/\chainB) using .filter + SendReply.kr
     -> /md/levels with replyIDs A=2001, B=2002. Pass-through (no sound-path change).
  B) Optional: after-group bus probes with explicit ordering and compile-time 2ch SynthDef.
- Provides tiny API used by the GUI script:
  ~md_startTestSource, ~md_stopTestSource, ~md_cleanup
  ~md_ensureRouting (NON-DESTRUCTIVE)
  ~md_reinstallReceiver
  ~md_attachProbesAB(busA, busB), ~md_attachProbeFinal(bus), ~md_detachAllProbes
Style
- var-first everywhere; descriptive lowercase names; no server.sync.
- AppClock for UI only; Server.default.bind for server ops.
- Generated audio only (tests); no SoundIn. No destructive freeAll in ensure.
*/

(
// === RUN ===
var s, ensureDictionaries, installReceiver, neutralizeFilter, installInlineMeters, installTestTap;
var makeAfterGroupProbeDef, attachProbeAB, detachAllProbes, ensureRouting;
var startTestSource, stopTestSource, banner, ids, rateHz, apiNote;

s = Server.default;
rateHz = 28;                 // ~30 Hz GUI-friendly
ids = (test: 1001, A: 2001, B: 2002, final: 2101);

// --- helpers / state ---------------------------------------------------------
ensureDictionaries = {
    var okA, okB;
    ~md_levelsById = (~md_levelsById ? IdentityDictionary.new);
    ~md_levelsById[ids[\A]] = (~md_levelsById[ids[\A]] ? [0.0, 0.0]);
    ~md_levelsById[ids[\B]] = (~md_levelsById[ids[\B]] ? [0.0, 0.0]);
    ~md_levelsById[ids[\test]] = (~md_levelsById[ids[\test]] ? [0.0, 0.0]);
    okA = ~md_levelsById[ids[\A]].notNil;
    okB = ~md_levelsById[ids[\B]].notNil;
    okA && okB
};

installReceiver = {
    var defName, doInstall;
    defName = \md_levels;
    doInstall = {
        var existing;
        existing = OSCdef(defName); // returns nil or the OSCdef
        if(existing.notNil) { existing.free };
        OSCdef(
            defName,
            { arg msg, time, addr, recvPort;
                var replyId, left, right, arr;
                // SendReply.kr emits: [ '/md/levels', nodeID, replyID, v0, v1, ... ]
                replyId = (msg.size > 2).if({ msg[2].asInteger }, { -1 });
                left    = (msg.size > 3).if({ msg[3].asFloat }, { 0.0 });
                right   = (msg.size > 4).if({ msg[4].asFloat }, { left });
                arr = [ left, right ];
                ~md_levelsById[replyId] = arr;
                ~md_lastMsgStamp = Main.elapsedTime;
            },
            '/md/levels',
            recvPort: NetAddr.langPort
        );
        ("OSCdef(\\md_levels) on /md/levels, recvPort=" ++ NetAddr.langPort).postln;
        true
    };
    doInstall.value
};

neutralizeFilter = { arg ndefKey;
    var keySym, apply;
    keySym = (ndefKey ? \chainA).asSymbol;
    apply = {
        // removeFilter() not available -> overwrite .filter with pass-through
        Ndef(keySym).filter(\md_meter, { arg in; var sig; sig = in; sig });
    };
    Server.default.bind({ apply.value });
};

installInlineMeters = {
    var installOne;
    installOne = { arg ndefKey, replyId;
        Server.default.bind({
            var keySym, meterKey;
            keySym = ndefKey.asSymbol;
            meterKey = \md_meter; // per-Ndef namespace; same symbol ok
            Ndef(keySym).filter(meterKey, { arg in;
                var sig, aL, aR, trig, r, id;
                r = rateHz;
                id = replyId;                 // replyID 2001 (A) / 2002 (B)
                sig = in.isArray.if({ in }, { [in, in] }); // mono-safe -> pair
                aL = Amplitude.kr(sig[0]).clip(0, 1);
                aR = Amplitude.kr(sig[1]).clip(0, 1);
                trig = Impulse.kr(r);
                SendReply.kr(trig, "/md/levels", [aL, aR], id);
                in // pass-through (no sound-path change)
            });
        });
    };
    installOne.value(\chainA, ids[\A]);
    installOne.value(\chainB, ids[\B]);
    true
};

installTestTap = { // fallback 1001 for demos when A/B are silent
    Server.default.bind({
        var haveSrc;
        haveSrc = Ndef(\testmelody).source.notNil;
        if(haveSrc) {
            Ndef(\testmelody).filter(\md_testmeter, { arg in;
                var sig, aL, aR, trig;
                sig = in.isArray.if({ in }, { [in, in] });
                aL = Amplitude.kr(sig[0]).clip(0, 1);
                aR = Amplitude.kr(sig[1]).clip(0, 1);
                trig = Impulse.kr(rateHz);
                SendReply.kr(trig, "/md/levels", [aL, aR], ids[\test]);
                in
            });
            "Test tap 1001 installed on \\testmelody".postln;
        } {
            "\\testmelody not present; no test tap added.".postln;
        };
    });
};

// --- Plan B: after-group probes (explicit ordering; compile-time 2ch) --------
makeAfterGroupProbeDef = {
    Server.default.bind({
        SynthDef(\md_busProbe2, { arg inBus=0, replyId=2001, rate=18;
            var sig, ampL, ampR, trig;
            sig = In.ar(inBus, 2); // compile-time 2ch
            ampL = Amplitude.kr(sig[0]).clip(0, 1);
            ampR = Amplitude.kr(sig[1]).clip(0, 1);
            trig = Impulse.kr(rate);
            SendReply.kr(trig, "/md/levels", [ampL, ampR], replyId);
        }).add;
    });
    true
};

attachProbeAB = {
    var ensureDef, makeOne;
    ensureDef = { makeAfterGroupProbeDef.value };
    makeOne = { arg ndefKey, replyId;
        var grp, syn, busIndex;
        Server.default.bind({
            // place probe AFTER the Ndef's group to guarantee source -> (tap) -> out
            grp = Group.after(Ndef(ndefKey).group);
            busIndex = Ndef(ndefKey).bus.index; // two channels
            syn = Synth(\md_busProbe2, [\inBus, busIndex, \replyId, replyId, \rate, rateHz], grp);
        });
        syn
    };
    ensureDef.value;
    if(~md_probeA.isNil) { ~md_probeA = makeOne.value(\chainA, ids[\A]) };
    if(~md_probeB.isNil) { ~md_probeB = makeOne.value(\chainB, ids[\B]) };
    true
};

detachAllProbes = {
    Server.default.bind({
        if(~md_probeA.notNil) { ~md_probeA.free; ~md_probeA = nil };
        if(~md_probeB.notNil) { ~md_probeB.free; ~md_probeB = nil };
    });
    // also neutralize inline filters if present
    neutralizeFilter.value(\chainA);
    neutralizeFilter.value(\chainB);
    true
};

// --- routing / sources (NON-DESTRUCTIVE ensure) ------------------------------
ensureRouting = {
    Server.default.bind({
        // keep this non-destructive: do NOT freeAll here
        Ndef(\chainA).ar(2); // ensure ar rate + stereo shape exists
        Ndef(\chainB).ar(2);
    });
    true
};

startTestSource = {
    Server.default.bind({
        if(Ndef(\testmelody).source.isNil) {
            Ndef(\testmelody, {
                var trig, seq, f, env, pan;
                trig = Impulse.kr(3.2);
                seq = Dseq([220,277.18,329.63,392,329.63,277.18,246.94], inf);
                f   = Demand.kr(trig, 0, seq);
                env = Decay2.kr(trig, 0.01, 0.35);
                pan = ToggleFF.kr(trig).linlin(0,1,-0.6,0.6);
                Pan2.ar(SinOsc.ar(f) * env * 0.25, pan)
            });
        };
        Ndef(\testmelody).ar(2);
    });
    installTestTap.value; // publishes replyID 1001
    true
};

stopTestSource = {
    Server.default.bind({
        if(Ndef(\testmelody).source.notNil) {
            // remove test tap and stop (idempotent)
            Ndef(\testmelody).filter(\md_testmeter, { arg in; in });
            Ndef(\testmelody).stop;
        };
    });
    true
};

// expose helpers as requested
~md_ensureRouting = ensureRouting;
~md_reinstallReceiver = installReceiver;
~md_attachProbesAB   = { arg busA=nil, busB=nil; attachProbeAB.value }; // signature kept
~md_detachAllProbes  = detachAllProbes;
~md_startTestSource  = startTestSource;
~md_stopTestSource   = stopTestSource;

// --- bring-up sequence -------------------------------------------------------
banner = {
    "--- MagicDisplayGUI Bring-up (non-destructive) ---".postln;
    ("ReplyIDs: test=" ++ ids[\test] ++ " A=" ++ ids[\A] ++ " B=" ++ ids[\B]).postln;
};

apiNote = {
    "[API] ~md_startTestSource, ~md_stopTestSource, ~md_ensureRouting, ~md_reinstallReceiver, ~md_attachProbesAB, ~md_detachAllProbes".postln;
};

banner.value;
ensureDictionaries.value;
s.waitForBoot;         // permitted here; non-destructive thereafter
~md_ensureRouting.();  // do not freeAll user nodes
~md_reinstallReceiver.();
installInlineMeters.value;  // A) preferred path
// -> To switch to Plan B later:
//    ~md_detachAllProbes.(); ~md_attachProbesAB.();

apiNote.value;
true
) // -> true
