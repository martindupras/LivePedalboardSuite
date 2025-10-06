// MagicDisplayGUI_Attach_ProbesAfterNdefs_v0.3.14.scd
// v0.3.14
// MD timestamp: 2025-09-25

/* Purpose
   - Attach A(2001)/B(2002) level probes directly *after* Ndef(\chainA/\chainB) groups.
   - Read each Ndef's actual output bus (handles 1ch or 2ch).
   - Neutralize any in-proxy meter/tap filters to avoid duplicate /md/levels.
   - Announces itself in the console so logs show what ran and in what order.

   Style
   - var-first; no non-local returns (^); descriptive lowercase names; known-good SC syntax.
*/

(
var announce, ensureProbeDefs, neutralizeInProxyMeters,
    detectInfo, attachAfterNdef, freeIfPlaying,
    aInfo, bInfo, ok;

announce = {
    var ok2;
    ok2 = true;
    "=== RUN MagicDisplayGUI_Attach_ProbesAfterNdefs_v0.3.14 ===".postln;
    ok2;
};

ensureProbeDefs = {
    var ok2, defMono, defStereo;

    ok2 = true;

    // mono probe (no Out, just SendReply)
    defMono = SynthDef(\md_levelProbe_1ch, { |inBus = 0, replyID = 2001|
        var sig, amp, ticker;
        sig = In.ar(inBus, 1);
        amp = Amplitude.kr(sig, 0.01, 0.30);
        ticker = Impulse.kr(20);
        SendReply.kr(ticker, "/md/levels", amp, replyID);
        // no audio output; silent by design
    }).add;

    // stereo probe (no Out, just SendReply)
    defStereo = SynthDef(\md_levelProbe_2ch, { |inBus = 0, replyID = 2001|
        var sig, amps, ticker;
        sig = In.ar(inBus, 2);
        amps = Amplitude.kr(sig, 0.01, 0.30);
        ticker = Impulse.kr(20);
        SendReply.kr(ticker, "/md/levels", amps, replyID);
        // no audio output; silent by design
    }).add;

    ok2;
};

neutralizeInProxyMeters = {
    var ok2;

    ok2 = true;

    // Overwrite any prior filters (meter/tap) to identity so they do nothing
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

// Gather Ndef info: existence, playing, bus index, channel count (clamped 1..2), and group
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

// Create a probe group *after* the Ndef's group and attach the proper probe synth
attachAfterNdef = { |info, replyID, groupVarSym, synthVarSym|
    var ok2, grp, synth, inBus, numCh, groupTarget;

    ok2 = true;
    grp = nil;
    synth = nil;
    inBus = info[\bus];
    numCh = info[\ch];
    groupTarget = info[\group];

    if (info[\exists] and: { inBus >= 0 } and: { groupTarget.notNil }) {
        s.bind({
            freeIfPlaying.value(thisProcess.interpreter.getVar(synthVarSym));
            thisProcess.interpreter.setVar(synthVarSym, nil);

            grp = Group.after(groupTarget);

            if (numCh == 1) {
                synth = Synth.tail(grp, \md_levelProbe_1ch, [\inBus, inBus, \replyID, replyID]);
            } {
                synth = Synth.tail(grp, \md_levelProbe_2ch, [\inBus, inBus, \replyID, replyID]);
            };

            thisProcess.interpreter.setVar(groupVarSym, grp);
            thisProcess.interpreter.setVar(synthVarSym, synth);
        });

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

// Make sure our base routing (toHardware + default test probe) exists WITHOUT killing Ndefs
if (~md_ensureRouting.notNil) { ~md_ensureRouting.value; };

// Avoid duplicate SendReply by neutralizing any in-proxy meters/taps
neutralizeInProxyMeters.value;

// Detect chains
aInfo = detectInfo.value(\chainA);
bInfo = detectInfo.value(\chainB);

// Attach probes *after* Ndef groups (ordering-safe)
attachAfterNdef.value(aInfo, 2001, \~md_probeGroupA, \~md_probeA);
attachAfterNdef.value(bInfo, 2002, \~md_probeGroupB, \~md_probeB);

"Attach_ProbesAfterNdefs: done.".postln;
)
