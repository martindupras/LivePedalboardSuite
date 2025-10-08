// LivePedalboardSystem-EnsureAudioOn.sc
// v0.1.0
// MD 20251006-1525

/* Purpose
   - Provide ensureAudioOn: prime generated audio only (no SoundIn), enforce stereo buses,
     and make the CURRENT chain audible. Keeps to Option A exclusivity when available.
Style
   - var-first; descriptive lowercase; Server.default.bind for server ops; AppClock for GUI; no server.sync.
*/

+ LivePedalboardSystem {

    ensureAudioOn {
        var s;
        s = Server.default;

        // Define sources/sinks idempotently and enforce stereo buses
        Server.default.bind({
            // Pulsed centered stereo source (easy to see on meters)
            if (Ndef(\testmelody).source.isNil) {
                Ndef(\testmelody, {
                    var trig = Impulse.kr(2.4);
                    var env  = Decay2.kr(trig, 0.01, 0.35);
                    var sig  = SinOsc.ar( Demand.kr(trig, 0, Dseq([220,277.18,329.63,392,329.63,277.18,246.94], inf)) ) * env * 0.25;
                    [sig, sig] // explicit stereo
                });
            };
            Ndef(\testmelody).ar(2);

            // Silent stereo placeholder
            if (Ndef(\stereoSilence).source.isNil) { Ndef(\stereoSilence, { Silent.ar(2) }) };
            Ndef(\stereoSilence).ar(2);

            // Ensure A/B sinks have 2‑ch audio buses pre‑armed
            Ndef(\chainA).ar(2);
            Ndef(\chainB).ar(2);
        });

        // Route CURRENT to \testmelody and enforce exclusivity when available
        if (this.pedalboard.respondsTo(\setSourceCurrent)) {
            this.pedalboard.setSourceCurrent(\testmelody);
        };
        if (this.pedalboard.respondsTo(\enforceExclusiveCurrentOptionA)) {
            this.pedalboard.enforceExclusiveCurrentOptionA(0.1);
        };

        // Make sure CURRENT is audible; safe fallback when playCurrent isn't available
        if (this.pedalboard.respondsTo(\playCurrent)) {
            this.pedalboard.playCurrent;
        } {
            Server.default.bind({
                if (Ndef(\chainA).isPlaying.not) { Ndef(\chainA).play(numChannels: 2) };
                if (Ndef(\chainB).isPlaying)     { Ndef(\chainB).stop };
            });
        };

        // One deferred assert after definitions settle (no server.sync)
        AppClock.sched(0.25, {
            if (this.pedalboard.respondsTo(\playCurrent)) {
                this.pedalboard.playCurrent;
            } {
                Server.default.bind({
                    if (Ndef(\chainA).isPlaying.not) { Ndef(\chainA).play(numChannels: 2) };
                    if (Ndef(\chainB).isPlaying)     { Ndef(\chainB).stop };
                });
            };
            nil
        });

        // Optional: print current chains for sanity
        if (this.pedalboard.respondsTo(\printChains)) { this.pedalboard.printChains };

        ^this
    }
}