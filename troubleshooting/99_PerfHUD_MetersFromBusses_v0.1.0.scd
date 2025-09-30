// 99_PerfHUD_MetersFromBusses.scd
// v0.1.0
// MD 2025-09-29 15:18 BST

(
var aBus, bBus;
var mkDefs, startMeters, uiNudge;

aBus = 2001;  // your tap buses
bBus = 2002;

mkDefs = {
    Server.default.bind({
        SynthDef(\md_levels4_from_busses, { arg inA=2001, inB=2002, rate=24;
            var a, b, la, ra, lb, rb, t;
            a  = In.ar(inA, 2);
            b  = In.ar(inB, 2);
            la = Amplitude.ar(a[0], 0.01, 0.20).clip(0, 1);
            ra = Amplitude.ar(a[1], 0.01, 0.20).clip(0, 1);
            lb = Amplitude.ar(b[0], 0.01, 0.20).clip(0, 1);
            rb = Amplitude.ar(b[1], 0.01, 0.20).clip(0, 1);
            t  = Impulse.kr(rate);
            SendReply.kr(t, '/md/levels_gui', A2K.kr([la, ra, lb, rb]));
            SendReply.kr(t, '/md/levels_bus', A2K.kr([la, ra, lb, rb]));
            SendReply.kr(t, '/ampA', A2K.kr([la, ra]));
            SendReply.kr(t, '/ampB', A2K.kr([lb, rb]));
        }).add;
    });
    "99: SynthDef \\md_levels4_from_busses installed.".postln;
};

startMeters = {
    if(~md_levelsSynth.notNil) { ~md_levelsSynth.free; ~md_levelsSynth = nil };
    Server.default.bind({
        ~md_levelsSynth = Synth(\md_levels4_from_busses, [\inA, aBus, \inB, bBus, \rate, 24]);
    });
    ("99: Started md_levels4_from_busses on A=" ++ aBus ++ "  B=" ++ bBus).postln;
};

uiNudge = {
    AppClock.sched(0.10, {
        if(~gui.notNil and: { ~gui.respondsTo(\highlightCurrentColumn) }) {
            ~gui.highlightCurrentColumn(\chainA);
        };
        if(~gui.notNil and: { ~gui.respondsTo(\showExpectation) }) {
            ~gui.showExpectation("HUD: meters bridged from A/B taps", 0);
        };
        nil
    });
};

mkDefs.value;
AppClock.sched(0.05, { startMeters.value; uiNudge.value; nil });
)
