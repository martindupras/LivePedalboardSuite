// Wire_AB_UsingSourceAssignment.scd
// v0.1.2
// MD 20251007-0945

/*
Purpose
- Define two stereo sources (\testmelodyA, \testmelodyB) that COMPUTE audio but DO NOT play to hardware.
- Route them into two sinks via the canonical JITLib pattern:
      Ndef(\chainA).source = Ndef(\testmelodyA);
      Ndef(\chainB).source = Ndef(\testmelodyB);
- Install SendPeakRMS taps on the sinks so LPDisplay can show meters:
      /peakrmsA (id=2001), /peakrmsB (id=2002)
- Provide two explicit switch helpers that ONLY play/stop the SINKS.

Style
- var-first; descriptive lowercase names; no server.sync; Server.default.bind for server ops.
- No isPlaying checks; switching = play one sink, stop the other.
*/

(
var rate, post, ensureStereoBus, defineSources, routeAb, installTaps, switchToA, switchToB;

// ----- small console helper
post = { |msg| ("[wire] " ++ msg).postln };

// ----- config
rate = 24;  // Peak/RMS update rate for taps

// ----- ensure sinks have stereo buses BEFORE routing (pre-arm)
ensureStereoBus = {
    Server.default.bind({
        Ndef(\chainA).ar(2);
        Ndef(\chainB).ar(2);
    });
    post.("pre-armed sinks to stereo: chainA/chainB .ar(2)");
};

// ----- define the two sources (stereo); evaluate only (NO .play)
defineSources = {
    Server.default.bind({
        if (Ndef(\testmelodyA).source.isNil) {
            Ndef(\testmelodyA, {
                var t = Impulse.kr(2.2);
                var e = Decay2.kr(t, 0.01, 0.30);
                var f = Demand.kr(t, 0, Dseq([220, 277.18, 329.63, 392], inf));
                (SinOsc.ar(f) * e * 0.22)!2
            });
            post.("defined \\testmelodyA (stereo) — evaluated only, not playing");
        };
        if (Ndef(\testmelodyB).source.isNil) {
            Ndef(\testmelodyB, {
                var t = Impulse.kr(3.1);
                var e = Decay2.kr(t, 0.02, 0.18);
                var f = Demand.kr(t, 0, Dseq([392, 329.63, 246.94, 220, 246.94], inf));
                (Pulse.ar(f, 0.35) * e * 0.20)!2
            });
            post.("defined \\testmelodyB (stereo) — evaluated only, not playing");
        };
    });
};

// ----- route sources into sinks using .source assignment (no \in, no <<>)
routeAb = {
    Server.default.bind({
        Ndef(\chainA).source = Ndef(\testmelodyA);
        Ndef(\chainB).source = Ndef(\testmelodyB);
    });
    post.("routed: chainA <- testmelodyA; chainB <- testmelodyB (sources are not playing to hardware)");
};

// ----- add SendPeakRMS taps on sinks (A=2001, B=2002)
installTaps = {
    Server.default.bind({
        Ndef(\chainA).clear(\meterTap);
        Ndef(\chainB).clear(\meterTap);

        Ndef(\chainA).filter(\meterTap, { |in|
            var sig = in.isArray.if({ in }, { [in, in] }); // coerce mono to stereo safely
            SendPeakRMS.kr(sig, rate, 3, '/peakrmsA', 2001);
            in
        });
        Ndef(\chainB).filter(\meterTap, { |in|
            var sig = in.isArray.if({ in }, { [in, in] });
            SendPeakRMS.kr(sig, rate, 3, '/peakrmsB', 2002);
            in
        });
    });
    post.("installed taps: /peakrmsA id=2001, /peakrmsB id=2002 (on SINKS)");
};

// ----- explicit switching (ONLY play/stop the sinks)
// switch to chain A (audible A, silent B)
switchToA = {
    Server.default.bind({
        Ndef(\chainA).play(numChannels: 2);
        Ndef(\chainB).stop;
    });
    post.("SWITCH: active = A  (executed: chainA.play; chainB.stop)");
};

// switch to chain B (audible B, silent A)
switchToB = {
    Server.default.bind({
        Ndef(\chainB).play(numChannels: 2);
        Ndef(\chainA).stop;
    });
    post.("SWITCH: active = B  (executed: chainB.play; chainA.stop)");
};

// ===== run steps once =====
ensureStereoBus.();
defineSources.();
routeAb.();
installTaps.();
switchToA.();  // start on A by default

// ===== expose simple helpers for ad‑hoc use in the post window =====
//     ~switch_to_a.()    // makes A audible, B silent
//     ~switch_to_b.()    // makes B audible, A silent

~switch_to_a = { switchToA.() };
~switch_to_b = { switchToB.() };
)