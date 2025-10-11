// MagicDisplayGUI_NewPath_Step1_ServerAndMeters.scd
// v0.2.1
// MD timestamp: 2025-09-25
/* Purpose
   - Cleanly (re)initialize the audio server tree, build a generated-only test signal path,
     and install a level probe that reports channel levels via /reply.
   - Publish public tilde helpers (~md_startTestSource, ~md_stopTestSource, ~md_cleanup) for GUI use.
   - Use compile-time channel counts (2ch) in SynthDefs.

   Style
   - var-first in every block; no non-local returns (^).
   - descriptive lowercase variables; no server.sync; server ops wrapped in s.bind where relevant.
   - generated audio only; probe reads a private bus.
*/

(
var prepareServerAndDefs, setupRouting, installOscReceiver, definePublicAPI, startStartupSequence;

prepareServerAndDefs = {
    var ok;
    ok = true;

    s.waitForBoot({
        var def_testSource, def_toHardware2, def_levelProbe2;

        s.initTree;
        s.defaultGroup.freeAll;

        ~levels = [0.0, 0.0];

        // Test source: stereo beeps
        def_testSource = SynthDef(\md_testSource, { |outBus = 0, amp = 0.20|
            var trig, freqSeq, sig, env, stereo;
            trig = Impulse.kr(2);
            freqSeq = Demand.kr(trig, 0, Dseq([60, 64, 67, 72].midicps, inf));
            env = EnvGen.kr(Env.perc(0.005, 0.20), trig);
            sig = SinOsc.ar(freqSeq) * env;
            stereo = [sig, DelayN.ar(sig, 0.03, 0.02)];
            Out.ar(outBus, stereo * amp);
        }).add;

        // Relay to hardware (fixed 2ch)
        def_toHardware2 = SynthDef(\md_toHardware_2ch, { |inBus = 0|
            var sig;
            sig = In.ar(inBus, 2);
            Out.ar(0, sig);
        }).add;

        // Level probe (fixed 2ch) → /reply
        def_levelProbe2 = SynthDef(\md_levelProbe_2ch, { |inBus = 0, sendID = 1001|
            var sig, amps, ticker;
            sig = In.ar(inBus, 2);
            amps = Amplitude.kr(sig, 0.01, 0.30);
            ticker = Impulse.kr(20);
            SendReply.kr(ticker, "/md/levels", amps, sendID);
        }).add;
    });

    ok;
};

setupRouting = {
    var ok;

    ok = true;

    s.bind({
        var defaultGroup;

        defaultGroup = s.defaultGroup;

        ~md_mixBus = Bus.audio(s, 2);

        ~md_srcGroup = Group.head(defaultGroup);
        ~md_meterGroup = Group.after(~md_srcGroup);
        ~md_outGroup = Group.after(~md_meterGroup);

        ~md_toHardware = Synth.tail(~md_outGroup, \md_toHardware_2ch, [\inBus, ~md_mixBus.index]);
        ~md_probe = Synth.tail(~md_meterGroup, \md_levelProbe_2ch, [\inBus, ~md_mixBus.index, \sendID, 1001]);

        ~md_testSynth = nil;
    });

    ok;
};

installOscReceiver = {
    var existing;

    existing = OSCdef(\md_levels);
    if (existing.notNil) {
        existing.free;
    };

    ~levels = [0.0, 0.0];

    OSCdef(\md_levels, { |msg, time, addr, recvPort|
        var tag, count, i, outArray;

        tag = msg[2];
        count = 0;
        i = 0;
        outArray = nil;

        if (tag == "/md/levels") {
            count = msg.size - 3;
            outArray = Array.newClear(count);
            i = 0;
            while { i < count } {
                outArray[i] = msg[3 + i].asFloat.clip(0.0, 1.0);
                i = i + 1;
            };
            ~levels = outArray;
        };
    }, '/reply');

    true;
};

definePublicAPI = {
    var ok;

    ok = true;

    ~md_startTestSource = {
        var ok2;
        ok2 = true;

        s.bind({
            if (~md_testSynth.notNil) {
                ~md_testSynth.free;
                ~md_testSynth = nil;
            };
            ~md_testSynth = Synth.tail(~md_srcGroup, \md_testSource, [\outBus, ~md_mixBus.index, \amp, 0.20]);
        });

        ok2;
    };

    ~md_stopTestSource = {
        var ok2;
        ok2 = true;

        if (~md_testSynth.notNil) {
            ~md_testSynth.free;
            ~md_testSynth = nil;
        };

        ok2;
    };

    ~md_cleanup = {
        var ok2;

        ok2 = true;

        if (~md_testSynth.notNil) {
            ~md_testSynth.free;
            ~md_testSynth = nil;
        };

        if (~md_probe.notNil) {
            ~md_probe.free;
            ~md_probe = nil;
        };

        if (~md_toHardware.notNil) {
            ~md_toHardware.free;
            ~md_toHardware = nil;
        };

        if (~md_outGroup.notNil) {
            ~md_outGroup.free;
            ~md_outGroup = nil;
        };
        if (~md_meterGroup.notNil) {
            ~md_meterGroup.free;
            ~md_meterGroup = nil;
        };
        if (~md_srcGroup.notNil) {
            ~md_srcGroup.free;
            ~md_srcGroup = nil;
        };

        if (~md_mixBus.notNil) {
            ~md_mixBus.free;
            ~md_mixBus = nil;
        };

        if (OSCdef(\md_levels).notNil) {
            OSCdef(\md_levels).free;
        };

        s.defaultGroup.freeAll;

        ok2;
    };

    ok;
};

startStartupSequence = {
    var ok;

    ok = true;

    "Step 1: preparing server + defs...".postln;
    prepareServerAndDefs.value;

    "Step 1: setting up routing (bus, groups, probe)...".postln;
    setupRouting.value;

    "Step 1: installing OSC receiver...".postln;
    installOscReceiver.value;

    // ✅ Publish the API so Step 2 can call it
    "Step 1: defining public API...".postln;
    definePublicAPI.value;

    "Step 1: ready. Use ~md_startTestSource.value to begin audio.".postln;

    ok;
};

// ---------- run ----------
startStartupSequence.value;

// Tips:
// ~md_startTestSource.value;
// ~md_stopTestSource.value;
// ~md_cleanup.value;
)
