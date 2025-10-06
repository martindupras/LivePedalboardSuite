// MagicDisplayGUI_Attach_TapsForNdefs_v0.3.7.scd
// v0.3.7
// MD timestamp: 2025-09-25

/* Purpose
   - For JITLib chains Ndef(\chainA) and Ndef(\chainB), install .filter taps
     that mirror their outputs to private 2ch busses for metering.
   - Attach probes to those busses (replyID 2001 for A, 2002 for B).
   - Provides a removal helper for the taps and busses.

   Style
   - var-first in every block; no non-local returns (^).
   - Uses .filter as you prefer; does not alter chain sound (passes input through).
*/

(
var setupBusTaps, removeBusTaps;

setupBusTaps = {
    var ok, haveA, haveB;

    ok = true;
    haveA = false;
    haveB = false;

    // preflight: Ndefs must exist
    if (Ndef(\chainA).notNil) { haveA = true; } { "Ndef(\\chainA) not found.".postln; };
    if (Ndef(\chainB).notNil) { haveB = true; } { "Ndef(\\chainB) not found.".postln; };

    if (haveA.not and: { haveB.not }) {
        "Neither chainA nor chainB found; nothing to attach.".postln;
    } {
        // free previous busses if any
        if (~md_busA.notNil) { ~md_busA.free; ~md_busA = nil; };
        if (~md_busB.notNil) { ~md_busB.free; ~md_busB = nil; };

        // allocate new private 2ch busses
        ~md_busA = if (haveA) { Bus.audio(s, 2) } { nil };
        ~md_busB = if (haveB) { Bus.audio(s, 2) } { nil };

        // install taps using .filter; each tap writes to its bus, then passes input through
        if (haveA) {
            Ndef(\chainA).filter(\mdProbeTapA, { |in|
                var outSig;
                outSig = in;
                Out.ar(~md_busA.index, outSig);
                outSig
            });
        };
        if (haveB) {
            Ndef(\chainB).filter(\mdProbeTapB, { |in|
                var outSig;
                outSig = in;
                Out.ar(~md_busB.index, outSig);
                outSig
            });
        };

        // attach probes to those busses
        if (~md_attachProbesAB.notNil) {
            ~md_attachProbesAB.value(
                busA: (if (haveA) { ~md_busA.index } { -1 }),
                busB: (if (haveB) { ~md_busB.index } { -1 })
            );
            ("Attached A bus=" ++ (if (haveA) { ~md_busA.index.asString } { "none" })
             ++ " B bus=" ++ (if (haveB) { ~md_busB.index.asString } { "none" })).postln;
        } {
            "Bring-up not loaded. Run MagicDisplayGUI_New_ServerBootAndProbe_v0.3.7.scd first.".postln;
        };
    };

    ok;
};

removeBusTaps = {
    var ok;

    ok = true;

    // remove taps if present
    if (Ndef(\chainA).notNil) {
        Ndef(\chainA).removeFilter(\mdProbeTapA);
    };
    if (Ndef(\chainB).notNil) {
        Ndef(\chainB).removeFilter(\mdProbeTapB);
    };

    // free private busses
    if (~md_busA.notNil) { ~md_busA.free; ~md_busA = nil; };
    if (~md_busB.notNil) { ~md_busB.free; ~md_busB = nil; };

    ok;
};

// ---------- run setup now ----------
setupBusTaps.value;

// Later, to remove taps + free busses:
// removeBusTaps.value;
)
