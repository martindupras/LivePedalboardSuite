// MagicDisplayGUI_Attach_ProbesAfterNdefs_v0.3.15.scd
// v0.3.15
// MD timestamp: 2025-09-25

/* Purpose
   - Attach A(2001)/B(2002) level probes directly *after* Ndef(\chainA/\chainB) groups.
   - Read each Ndef's actual output bus (mono or stereo).
   - Neutralize any in-proxy meter/tap filters to avoid duplicate /md/levels.
   - Announce actions in console so logs clearly show what ran.

   Style
   - var-first; no non-local returns (^); descriptive lowercase names; known-good SC syntax.
*/

(
var announce, ensureProbeDefs, neutralizeInProxyFilters,
    detectInfo, freeIfPlaying, attachAfterNdef,
    aInfo, bInfo, ok;

announce = {
    var ok2;
    ok2 = true;
    "=== RUN MagicDisplayGUI_Attach_ProbesAfterNdefs_v0.3.15 ===".postln;
    ok2;
};

ensureProbeDefs = {
    var ok2, defMono, defStereo;

    ok2 = true;

    // mono probe: reads 1 channel, sends a single float
    defMono = SynthDef(\md_levelProbe_1ch, { |inBus = 0, replyID = 2001|
        var sig, amp, ticker;
        sig = In.ar(inBus, 1);
        amp = Amplitude.kr(sig, 0.01, 0.30);
        ticker = Impulse.kr(20);
        SendReply.kr(ticker, "/md/levels", amp, replyID);
        // no audio output
    }).add;

    // stereo probe: reads 2 channels, sends an array of two floats
    defStereo = SynthDef(\md_levelProbe_2ch, { |inBus = 0, replyID = 2001|
        var sig, amps, ticker;
        sig = In.ar(inBus, 2);
        amps = Amplitude.kr(sig, 0.01, 0.30);
        ticker = Impulse.kr(20);
        SendReply.kr(ticker, "/md/levels", amps, replyID);
        // no audio output
    }).add;

    ok2;
};

neutralizeInProxyFilters = {
    var ok2;

    ok2 = true;

    // Overwrite prior filters/taps to identity so they do nothing
    if (Ndef(\chainA).notNil and: { Ndef(\chainA).respondsTo(\filter) }) {
        Ndef(\chainA).filter(\mdMeterA, { |in| in });
        Ndef(\chainA).filter(\mdProbeTapA, { |in| in });
    };
    if (Ndef(\chainB).notNil and: { Ndef(\chainB).respondsTo(\filter) }) {
        Ndef(\chainB).filter(\mdMeterB, { |in| in });
        Ndef(\chainB).filter(\mdProbeTapB, { |in| in });
    };

    ok2;
};

// Inspect an Ndef and report (exists, playing, bus index, channel count, group)
detectInfo = { |name|
    var proxy, info, isThere, isPlaying, busIdx, numCh, group;

    proxy = Ndef(name);

    isThere = proxy.notNil;
    isPlaying = false;
    busIdx = -1;
    numCh = 2;
    group = nil;

    if (isThere) {
        isPlaying = proxy.isPlaying;
        if (proxy.bus.notNil) {
            busIdx = proxy.bus.index;
            if (proxy.bus.respondsTo(\numChannels)) {
                numCh = proxy.bus.numChannels.max(1).min(2);
            };
        };
        group = proxy.group;
    };

    info = (
        key: name,
        exists: isThere,
        playing: isPlaying,
        bus: busIdx,
        ch: numCh,
        group: group
    );

    (name.asString ++ ": exists=" ++ isThere.asString
        ++ " playing=" ++ isPlaying.asString
        ++ " bus=" ++ busIdx.asString
        ++ " ch=" ++ numCh.asString).postln;

    info;
};

freeIfPlaying = { |node|
    var ok2;
    ok2 = true;
    if (node.notNil) {
        if (node.respondsTo(\isPlaying)) {
            if (node.isPlaying) { node.free; };
        } {
            if (node.respondsTo(\free)) { node.free; };
        };
    };
    ok2;
};

// Create a probe group AFTER the Ndef's group and attach the proper probe synth.
// Uses setter closures to store references in ~vars (no reflection).
attachAfterNdef = { |info, replyID, setGroupFunc, setSynthFunc, freeOldSynthFunc|
    var ok2, grp, synth, inBus, numCh, groupTarget;

    ok2 = true;
    grp = nil;
    synth = nil;
    inBus = info[\bus];
    numCh = info[\ch];
    groupTarget = info[\group];

    if (info[\exists] and: { inBus >= 0 } and: { groupTarget.notNil }) {
        // free the previous synth if any (quietly)
        freeOldSynthFunc.value;

        s.bind({
            grp = Group.after(groupTarget);

            if (numCh == 1) {
                synth = Synth.tail(grp, \md_levelProbe_1ch, [\inBus, inBus, \replyID, replyID]);
            } {
                synth = Synth.tail(grp, \md_levelProbe_2ch, [\inBus, inBus, \replyID, replyID]);
            };
        });

        setGroupFunc.value(grp);
        setSynthFunc.value(synth);

        ((info[\key].asString ++ " probe attached: nodeID=" ++ synth.nodeID.asString
            ++ " afterGroup=" ++ grp.nodeID.asString
            ++ " inBus=" ++ inBus.asString
            ++ " ch=" ++ numCh.asString
            ++ " replyID=" ++ replyID.asString)).postln;
    } {
        (info[\key].asString ++ ": cannot attach (exists=" ++ info[\exists].asString
            ++ " playing=" ++ info[\playing].asString
            ++ " bus=" ++ info[\bus].asString ++ ").").postln;
    };

    ok2;
};

// ---------- run sequence ----------
ok = true;
announce.value;

ensureProbeDefs.value;

// Ensure our base routing exists WITHOUT clearing your Ndefs
if (~md_ensureRouting.notNil) { ~md_ensureRouting.value; };

// Avoid duplicate SendReply by neutralizing any in-proxy filters/taps
neutralizeInProxyFilters.value;

// Detect chains (prints status)
aInfo = detectInfo.value(\chainA);
bInfo = detectInfo.value(\chainB);

// Attach probes AFTER the Ndef groups (ordering-safe)
attachAfterNdef.value(
    aInfo, 2001,
    { |g| ~md_probeGroupA = g },            // set group
    { |sy| ~md_probeA = sy },               // set synth
    { freeIfPlaying.value(~md_probeA); ~md_probeA = nil }  // free old synth if any
);

attachAfterNdef.value(
    bInfo, 2002,
    { |g| ~md_probeGroupB = g },
    { |sy| ~md_probeB = sy },
    { freeIfPlaying.value(~md_probeB); ~md_probeB = nil }
);

"Attach_ProbesAfterNdefs: done.".postln;
)
