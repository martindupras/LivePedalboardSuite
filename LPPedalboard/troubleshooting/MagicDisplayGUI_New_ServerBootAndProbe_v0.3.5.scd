// MagicDisplayGUI_New_ServerBootAndProbe_v0.3.5.scd
// v0.3.5
// MD timestamp: 2025-09-25

/* Purpose
   - Reboot the server to a known-clean state.
   - Define SynthDefs (fixed 2ch), create a private bus, groups, relay-to-hardware and a level probe.
   - Install an OSC receiver bound to '/md/levels' (matches SendReply).
   - Publish robust public API with auto-heal:
       ~md_reinstallReceiver, ~md_ensureRouting, ~md_startTestSource, ~md_stopTestSource, ~md_cleanup

   Style
   - var-first in every block; no non-local returns (^).
   - descriptive lowercase names; no server.sync; server ops wrapped in s.bind.
   - generated audio only; probe reads a private bus; compile-time channel counts.
*/

(
var bootServerClean, defineSynthDefs, reinstallReceiver, createRouting, definePublicAPI, printSummary;

bootServerClean = {
    var ok;

    ok = true;

    // Close any MagicDisplayGUI windows
    {
        var windows, i, w, nameString;
        windows = Window.allWindows;
        i = 0;
        while { i < windows.size } {
            w = windows[i];
            nameString = w.name.asString;
            if (nameString.beginsWith("MagicDisplayGUI")) {
                w.close;
            };
            i = i + 1;
        };
    }.value;

    // Reset client-side state vars
    ~levels = [0.0, 0.0];
    ~md_lastLevelAt = 0.0;
    ~md_testSynth = nil;
    ~md_probe = nil;
    ~md_toHardware = nil;
    ~md_mixBus = nil;
    ~md_srcGroup = nil;
    ~md_meterGroup = nil;
    ~md_outGroup = nil;

    // Reboot server to a known state
    if (s.serverRunning) {
        s.quit;
    };
    s.boot;

    s.waitForBoot({
        var ok2;
        ok2 = true;
        s.initTree;
        s.defaultGroup.freeAll;
        ok2;
    });

    ok;
};

defineSynthDefs = {
    var ok, def_testSource, def_toHardware2, def_levelProbe2;

    ok = true;

    // Test source (stereo beeps)
    def_testSource = SynthDef(\md_testSource, { |outBus = 0, amp = 0.28|
        var trig, freqSeq, sig, env, stereo;
        trig = Impulse.kr(2);
        freqSeq = Demand.kr(trig, 0, Dseq([60, 64, 67, 72].midicps, inf));
        env = EnvGen.kr(Env.perc(0.005, 0.20), trig);
        sig = SinOsc.ar(freqSeq) * env;
        stereo = [sig, DelayN.ar(sig, 0.03, 0.02)];
        Out.ar(outBus, stereo * amp);
    }).add;

    // Relay to hardware (2ch fixed)
    def_toHardware2 = SynthDef(\md_toHardware_2ch, { |inBus = 0|
        var sig;
        sig = In.ar(inBus, 2);
        Out.ar(0, sig);
    }).add;

    // Level probe (2ch fixed) → '/md/levels'
    // Message format: ['/md/levels', nodeID, replyID, val1, val2, ...]
    def_levelProbe2 = SynthDef(\md_levelProbe_2ch, { |inBus = 0, replyID = 1001|
        var sig, amps, ticker;
        sig = In.ar(inBus, 2);
        amps = Amplitude.kr(sig, 0.01, 0.30);
        ticker = Impulse.kr(20);
        SendReply.kr(ticker, "/md/levels", amps, replyID);
    }).add;

    ok;
};

// Install or re-install the OSC receiver (binds to '/md/levels')
reinstallReceiver = {
    var existing;

    existing = OSCdef(\md_levels);
    if (existing.notNil) {
        existing.free;
    };

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

                ~levels = outArray;
                ~md_lastLevelAt = Main.elapsedTime;
            };
        },
        '/md/levels',
        recvPort: NetAddr.langPort
    );

    true;
};

// Create routing (fresh bus + fresh groups + relay + probe). Clears default group first.
createRouting = {
    var ok;

    ok = true;

    s.bind({
        var defaultGroup;

        defaultGroup = s.defaultGroup;

        // Clear any stale nodes from previous runs
        s.defaultGroup.freeAll;

        // Fresh bus
        if (~md_mixBus.notNil) {
            ~md_mixBus.free;
            ~md_mixBus = nil;
        };
        ~md_mixBus = Bus.audio(s, 2);

        // Fresh groups in strict order: src -> meter -> out
        ~md_srcGroup = Group.head(defaultGroup);
        ~md_meterGroup = Group.after(~md_srcGroup);
        ~md_outGroup = Group.after(~md_meterGroup);

        // Relay and probe (safe even without source)
        ~md_toHardware = Synth.tail(~md_outGroup, \md_toHardware_2ch, [\inBus, ~md_mixBus.index]);
        ~md_probe = Synth.tail(~md_meterGroup, \md_levelProbe_2ch, [\inBus, ~md_mixBus.index, \replyID, 1001]);

        // No source yet
        ~md_testSynth = nil;
    });

    ok;
};

definePublicAPI = {
    var ok;

    ok = true;

    ~md_reinstallReceiver = {
        var ok2;
        ok2 = true;
        reinstallReceiver.value;
        ok2;
    };

    // Always rebuild routing to avoid stale groups after a server reboot
    ~md_ensureRouting = {
        var ok2;
        ok2 = true;
        createRouting.value;
        reinstallReceiver.value;
        ok2;
    };

    ~md_startTestSource = {
        var ok2;

        ok2 = true;

        ~md_ensureRouting.value;

        s.bind({
            if (~md_testSynth.notNil) {
                ~md_testSynth.free;
                ~md_testSynth = nil;
            };
            ~md_testSynth = Synth.tail(~md_srcGroup, \md_testSource, [\outBus, ~md_mixBus.index, \amp, 0.28]);
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

    // Clean everything (leave server running)
    ~md_cleanup = {
        var ok2;

        ok2 = true;

        s.bind({
            s.defaultGroup.freeAll;
        });

        if (~md_mixBus.notNil) {
            ~md_mixBus.free;
            ~md_mixBus = nil;
        };

        if (OSCdef(\md_levels).notNil) {
            OSCdef(\md_levels).free;
        };

        ~levels = [0.0, 0.0];
        ~md_lastLevelAt = 0.0;

        ~md_testSynth = nil;
        ~md_probe = nil;
        ~md_toHardware = nil;
        ~md_srcGroup = nil;
        ~md_meterGroup = nil;
        ~md_outGroup = nil;

        ok2;
    };

    ok;
};

printSummary = {
    var ok;

    ok = true;

    "MagicDisplayGUI bring-up complete:".postln;
    ("  mixBus index: " ++ (if (~md_mixBus.notNil) { ~md_mixBus.index } { "nil" }).asString).postln;
    "  API: ~md_startTestSource, ~md_stopTestSource, ~md_cleanup".postln;
    "  Guards: ~md_ensureRouting, ~md_reinstallReceiver".postln;
    "  OSC: listening on /md/levels".postln;

    ok;
};

// ---------- Run sequence ----------
"Booting server clean...".postln; bootServerClean.value;
"Defining SynthDefs...".postln; defineSynthDefs.value;
"Creating routing...".postln; createRouting.value;
"Installing OSC receiver...".postln; reinstallReceiver.value;
"Publishing public API...".postln; definePublicAPI.value;
printSummary.value;

// Usage:
// ~md_startTestSource.value;
// ~md_stopTestSource.value;
// ~md_cleanup.value;
// ~md_ensureRouting.value;
// ~md_reinstallReceiver.value;
)
