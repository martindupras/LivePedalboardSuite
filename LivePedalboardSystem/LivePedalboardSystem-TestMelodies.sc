// LivePedalboardSystem-TestMelodies.sc
// v0.1.0
// MD 20251006-1648

/*
Purpose
- Provide distinct, stereo Ndefs: \testmelodyA and \testmelodyB, OFF by default.
- Offer a small routing helper to assign them to chain A/B when you want to audition which chain is audible.

Style
- var-first; descriptive lowercase names; no single-letter locals.
- No server.sync; use Server.default.bind for Ndef definitions only.
- Does not auto-play or auto-switch; respects your pedalboard’s exclusivity policy.
*/

+ LivePedalboardSystem {

    installTestMelodies {
        var installDefs;

        installDefs = {
            Server.default.bind({
                // --- \testmelodyA: pulsed ascending figure (clear identity)
                if (Ndef(\testmelodyA).source.isNil) {
                    Ndef(\testmelodyA, {
                        var trig, env, freqs, nextFreq, sig;
                        trig = Impulse.kr(2.2);
                        env  = Decay2.kr(trig, 0.01, 0.30);
                        freqs = Dseq([220, 277.18, 329.63, 392], inf);
                        nextFreq = Demand.kr(trig, 0, freqs);
                        sig = SinOsc.ar(nextFreq) * env * 0.25;
                        [sig, sig] // explicit stereo
                    });
                };
                Ndef(\testmelodyA).ar(2);

                // --- \testmelodyB: different rhythm & timbre (pulse), descending turn
                if (Ndef(\testmelodyB).source.isNil) {
                    Ndef(\testmelodyB, {
                        var trig, env, freqs, nextFreq, sig;
                        trig = Impulse.kr(3.1);             // rate differs from A
                        env  = Decay2.kr(trig, 0.02, 0.18); // shorter tail
                        freqs = Dseq([392, 329.63, 246.94, 220, 246.94], inf);
                        nextFreq = Demand.kr(trig, 0, freqs);
                        sig = Pulse.ar(nextFreq, 0.35) * env * 0.22;
                        [sig, sig] // explicit stereo
                    });
                };
                Ndef(\testmelodyB).ar(2);
            });
        };

        installDefs.value;
        ^this
    }

    routeTestMelodiesToAB {
        var pb;

        pb = this.pedalboard;

        // Prefer pedalboard’s public API if available; otherwise definitions remain ready.
        if (pb.notNil and: { pb.respondsTo(\setSourceA) and: { pb.respondsTo(\setSourceB) } }) {
            pb.setSourceA(\testmelodyA);
            pb.setSourceB(\testmelodyB);
        };

        ^this
    }
}
