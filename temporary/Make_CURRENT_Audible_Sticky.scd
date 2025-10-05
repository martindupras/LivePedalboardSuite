// Make_CURRENT_Audible_Sticky.scd
// v0.1.1
// MD 20251005-1708

/*
Purpose
- Route CURRENT -> \testmelody and play it, with two deferred retries (150/300 ms)
  to survive brief MPB rebuilds/crossfades.
Style
- var-first; lowercase; no server.sync; AppClock for timing; safe responders.
*/

(
var pb, ensure, doOnce;

pb = ~system.tryPerform(\pedalboard);

ensure = {
    if(pb.notNil) {
        if(pb.respondsTo(\setSourceCurrent)) { pb.setSourceCurrent(\testmelody) };
        if(pb.respondsTo(\playCurrent))      { pb.playCurrent };
    };
    Server.default.bind({
        if(Ndef(\chainA).notNil) { Ndef(\chainA).ar(2) };
        if(Ndef(\chainB).notNil) { Ndef(\chainB).ar(2) };
    });
    "🔊 CURRENT -> \\testmelody (sticky step)".postln;
};

doOnce = {
    // materialize sources/endpoints idempotently
    Server.default.bind({
        if(Ndef(\testmelody).source.isNil) {
            Ndef(\testmelody, {
                var trig = Impulse.kr(3.2);
                var f    = Demand.kr(trig, 0, Dseq([220,277.18,329.63,392,329.63,277.18,246.94], inf));
                var env  = Decay2.kr(trig, 0.01, 0.35);
                var pan  = ToggleFF.kr(trig).linlin(0,1,-0.6,0.6);
                Pan2.ar(SinOsc.ar(f) * env * 0.25, pan)
            });
        };
        Ndef(\testmelody).ar(2);
        if(Ndef(\ts0).source.isNil) { Ndef(\ts0, { Silent.ar(2) }) };
        Ndef(\ts0).ar(2);
        if(Ndef(\chainA).notNil) { Ndef(\chainA).ar(2) };
        if(Ndef(\chainB).notNil) { Ndef(\chainB).ar(2) };
    });

    // first assert + two gentle retries
    ensure.();
    AppClock.sched(0.150, { ensure.(); nil });
    AppClock.sched(0.300, { ensure.(); nil });
};

doOnce.();
)