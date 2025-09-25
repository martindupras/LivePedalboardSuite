// MagicDisplayGUI_Reenable_FilterMeters_v0.3.12.scd
// v0.3.12
// MD timestamp: 2025-09-25

/* Purpose
   - Install .filter meters *inside* Ndef(\chainA) and Ndef(\chainB):
       * compute Amplitude.kr on the proxy signal
       * SendReply.kr directly to '/md/levels' with replyIDs 2001/2002
       * return the input signal unchanged (no audio change)
   - Neutralize any previous tap filters (bus mirroring) by overwriting them to identity.
   - Free any old external probe synths/busses used for taps; they are no longer needed.
   - Announces itself in the console.

   Style
   - var-first; no non-local returns (^); descriptive lowercase variables; known-good SC syntax.
*/

(
var hasA, hasB, attackTime, releaseTime, updateRateHz,
    installMeterFor, neutralizeTap, freeIfPlaying;

"=== RUN MagicDisplayGUI_Reenable_FilterMeters_v0.3.12 ===".postln;

hasA = (Ndef(\chainA).notNil);
hasB = (Ndef(\chainB).notNil);

attackTime = 0.01;
releaseTime = 0.30;
updateRateHz = 20;

// overwrite old bus-mirror taps to identity (safe if they don't exist)
neutralizeTap = { |name, key|
    var proxy, canFilter;
    proxy = Ndef(name);
    canFilter = false;
    if (proxy.notNil) {
        canFilter = proxy.respondsTo(\filter);
        if (canFilter) {
            proxy.filter(key, { |inputSig|  // identity pass-through
                var outSig;
                outSig = inputSig;
                outSig
            });
        };
    };
};

// install the actual meter filter (no bus, direct SendReply)
installMeterFor = { |name, replyID, key|
    var proxy, canFilter, ok;
    proxy = Ndef(name);
    canFilter = false;
    ok = true;

    if (proxy.notNil) {
        canFilter = proxy.respondsTo(\filter);
        if (canFilter) {
            proxy.filter(key, { |inputSig|
                var amps, ticker, outSig;
                amps = Amplitude.kr(inputSig, attackTime, releaseTime);
                ticker = Impulse.kr(updateRateHz);
                SendReply.kr(ticker, "/md/levels", amps, replyID);
                outSig = inputSig; // no audio change
                outSig
            });
            (("Installed meter on " ++ name.asString) ++ " (replyID " ++ replyID.asString ++ ").").postln;
        } {
            (name.asString ++ ": .filter not supported; skipped.").postln;
        };
    } {
        (name.asString ++ " not found; skipped.").postln;
    };

    ok;
};

// neutralize any prior tap keys used before (safe no-ops if absent)
neutralizeTap.value(\chainA, \mdProbeTapA);
neutralizeTap.value(\chainB, \mdProbeTapB);

// install in-proxy meters (distinct keys so they are idempotent)
if (hasA) { installMeterFor.value(\chainA, 2001, \mdMeterA); };
if (hasB) { installMeterFor.value(\chainB, 2002, \mdMeterB); };

// free old external probe synths/busses (from the tap approach)
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

freeIfPlaying.value(~md_probeA);  ~md_probeA = nil;
freeIfPlaying.value(~md_probeB);  ~md_probeB = nil;

if (~md_busA.notNil) { ~md_busA.free; ~md_busA = nil; };
if (~md_busB.notNil) { ~md_busB.free; ~md_busB = nil; };

"Installed in-proxy meters; removed external probes/tap busses.".postln;
)
