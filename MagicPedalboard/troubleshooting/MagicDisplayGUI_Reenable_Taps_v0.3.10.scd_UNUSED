// MagicDisplayGUI_Reenable_Taps_v0.3.10.scd
// v0.3.10
// MD timestamp: 2025-09-25

/* Purpose
   - Make A/B meters move reliably by reinstating .filter taps on Ndef(\chainA/\chainB).
   - Mirror audio to private stereo busses, then attach A(2001)/B(2002) probes to those busses.
   - Non-destructive: does not modify chain sound; taps return 'in'.

   Style
   - var-first in every block; no non-local returns (^).
*/

(
var ok, haveA, haveB, tapBusA, tapBusB;

("MagicDisplayGUI_Reenable_Taps_v0.3.10.scd").postln;

ok = true;
haveA = (Ndef(\chainA).notNil);
haveB = (Ndef(\chainB).notNil);

~md_ensureRouting.value;

// (re)allocate private tap busses
if (~md_busA.notNil) { ~md_busA.free; ~md_busA = nil; };
if (~md_busB.notNil) { ~md_busB.free; ~md_busB = nil; };

~md_busA = if (haveA) { Bus.audio(s, 2) } { nil };
~md_busB = if (haveB) { Bus.audio(s, 2) } { nil };

tapBusA = if (~md_busA.notNil) { ~md_busA.index } { -1 };
tapBusB = if (~md_busB.notNil) { ~md_busB.index } { -1 };

// install/overwrite taps (identity pass-through + mirror to tap bus)
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

// attach probes to tap busses (free stale ones first)
s.bind({
    if (~md_probeA.notNil) { ~md_probeA.free; ~md_probeA = nil; };
    if (~md_probeB.notNil) { ~md_probeB.free; ~md_probeB = nil; };

    if (tapBusA >= 0) {
        ~md_probeA = Synth.tail(~md_meterGroup, \md_levelProbe_2ch, [\inBus, tapBusA, \replyID, 2001]);
    };
    if (tapBusB >= 0) {
        ~md_probeB = Synth.tail(~md_meterGroup, \md_levelProbe_2ch, [\inBus, tapBusB, \replyID, 2002]);
    };
});

("A probe -> inBus " ++ tapBusA.asString).postln;
("B probe -> inBus " ++ tapBusB.asString).postln;

ok;
)
