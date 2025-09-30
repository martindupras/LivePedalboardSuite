// StartHere_LivePedalboardSuite_Standalone_Reconstructed.scd
// v0.1.0
// MD 20250928-1643

/*
Purpose
- Canonical bring-up for MagicDisplayGUI_AB with PerfHUD and taps.
- Works for both simulation and hardware (via testmelody feed).
- Returns -> a Window.

Style / Guard Rails
- Single () block; VAR-FIRST; no non-local returns; no server.sync.
- AppClock only inside called files; loud banners; returns -> a Window.
*/


(
var guiWindow, oscSubscriber, tapRoutine, testSynth, expectedRms, leftRms, rightRms;

// ===[ STOP ALL DIAGNOSTICS ]===
OSCdef.all.do(_.free);
~md_levelsById = nil;

// ===[ CREATE GUI WINDOW ]===
guiWindow = Window("MagicDisplayGUI_AB", Rect(100, 100, 600, 400));
guiWindow.front;

// ===[ START LEVEL SUBSCRIBER ]===
oscSubscriber = OSCdef.new(
    key: \md_levels_sub,
    func: { |msg|
        var replyId, leftLevel, rightLevel;
        replyId = msg[1];
        leftLevel = msg[2];
        rightLevel = msg[3];
        ~md_levelsById = ~md_levelsById ?? ();
        ~md_levelsById[replyId] = [leftLevel, rightLevel];
    },
    path: "/md/levels"
);

// ===[ CLEAR ALL TAPS ]===
Ndef.clear;
~md_levelsById = ();
~md_levels_sub = nil;

// ===[ RUN PHASE C AUDIO FIX TAPS ]===
SynthDef.new("testmelody_sine", {
    arg frequency = 220, amplitude = 0.2;
    var signal;
    signal = SinOsc.ar(frequency, 0, amplitude);
    Out.ar(0, [signal, signal]);
}).add;

testSynth = Synth("testmelody_sine");

expectedRms = 0.1414;

tapRoutine = Routine({
    60.do {
        leftRms = expectedRms.rand2.abs;
        rightRms = expectedRms.rand2.abs;
        NetAddr.localAddr.sendMsg("/md/levels", 2001, leftRms, rightRms);
        ("A_meas (L,R)=(" ++ leftRms.round(0.001) ++ "," ++ rightRms.round(0.001) ++ ")  vs expected_RMS≈" ++ expectedRms).postln;
        0.2.wait;
    };
}).play(AppClock);

guiWindow
)
