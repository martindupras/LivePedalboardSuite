// 02C_Testmelody_Level_Boost.scd
// v0.1.0
// MD 20250928-2015
(
// Purpose: temporarily raise testmelody output so meters are clearly visible.
// Style: var-first; server ops in Server.default.bind.

var boost;
boost = {
    Server.default.bind({
        // Reinstall the same testmelody with a slightly higher amp (0.22 -> 0.40)
        Ndef(\testmelody, {
            var trig = Impulse.kr(2.4);
            var sel  = Demand.kr(trig, 0, Dwhite(0, 4, inf));
            var scale = [60, 62, 64, 67, 69];
            var f = Select.kr(sel, scale).midicps;
            var env = Decay2.kr(trig, 0.01, 0.35);
            var pan = LFNoise1.kr(0.35).range(-0.6, 0.6);
            Pan2.ar(SinOsc.ar(f) * env * 0.40, pan)  // <-- boosted
        });
    });
    "⬆️ testmelody amp boosted (0.40).".postln;
};
boost.value;
)
