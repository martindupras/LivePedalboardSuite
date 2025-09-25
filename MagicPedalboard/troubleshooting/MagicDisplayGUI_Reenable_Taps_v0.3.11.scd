// MagicDisplayGUI_Reenable_Taps_v0.3.11.scd
// v0.3.11
// MD timestamp: 2025-09-25

/* Purpose
   - Reinstall .filter taps on Ndef(\chainA/\chainB) to mirror audio to private 2ch busses.
   - Attach probes A(2001) and B(2002) to those busses.
   - Quiet stale frees; print nodeIDs of created probes.
   - Announces itself in the console.

   Style
   - var-first; no non-local returns (^); descriptive lowercase variables.
*/

(
var haveA, haveB, tapBusA, tapBusB, newProbeA, newProbeB, freeIfPlaying;

"=== RUN MagicDisplayGUI_Reenable_Taps_v0.3.11 ===".postln;

haveA = (Ndef(\chainA).notNil);
haveB = (Ndef(\chainB).notNil);

~md_ensureRouting.value;

freeIfPlaying = { |node|
    var ok;
    ok = true;
    if (node.notNil) {
        if (node.respondsTo(\isPlaying)) {
            if (node.isPlaying) { node.free; };
        } {
            if (node.respondsTo(\free)) { node.free; };
        };
    };
    ok;
};

// fresh tap busses
if (~md_busA.notNil) { ~md_busA.free; ~md_busA = nil; };
if (~md_busB.notNil) { ~md_busB.free; ~md_busB = nil; };

~md_busA = if (haveA) { Bus.audio(s, 2) } { nil };
~md_busB = if (haveB) { Bus.audio(s, 2) } { nil };

tapBusA = if (~md_busA.notNil) { ~md_busA.index } { -1 };
tapBusB = if (~md_busB.notNil) { ~md_busB.index } { -1 };

// (re)install taps (identity pass-through + mirror to tap bus)
if (haveA) {
    Ndef(\chainA).filter(\mdProbeTapA, { |in|
        var outSig;
        outSig = in;
        Out.ar(tapBusA, outSig);
        outSig
    });
    ("Tap A -> bus " ++ tapBusA.asString).postln;
} {
    "Ndef(\\chainA) not found; A tap skipped.".postln;
};

if (haveB) {
    Ndef(\chainB).filter(\mdProbeTapB, { |in|
        var outSig;
        outSig = in;
        Out.ar(tapBusB, outSig);
        outSig
    });
    ("Tap B -> bus " ++ tapBusB.asString).postln;
} {
    "Ndef(\\chainB) not found; B tap skipped.".postln;
};

// attach probes (free stale ones only if playing)
s.bind({
    freeIfPlaying.value(~md_probeA);
    ~md_probeA = nil;

    freeIfPlaying.value(~md_probeB);
    ~md_probeB = nil;

    newProbeA = nil;
    newProbeB = nil;

    if (tapBusA >= 0) {
        ~md_probeA = Synth.tail(~md_meterGroup, \md_levelProbe_2ch, [\inBus, tapBusA, \replyID, 2001]);
        newProbeA = ~md_probeA;
    };
    if (tapBusB >= 0) {
        ~md_probeB = Synth.tail(~md_meterGroup, \md_levelProbe_2ch, [\inBus, tapBusB, \replyID, 2002]);
        newProbeB = ~md_probeB;
    };
});

if (newProbeA.notNil) { ("A probe nodeID: " ++ newProbeA.nodeID.asString).postln; } { "A probe not created.".postln; };
if (newProbeB.notNil) { ("B probe nodeID: " ++ newProbeB.nodeID.asString).postln; } { "B probe not created.".postln; };

"Re-enable taps: done.".postln;
)
